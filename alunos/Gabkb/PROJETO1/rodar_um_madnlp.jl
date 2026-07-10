using JuMP
using MadNLP
using Printf

# ============================================================
# USO:
#
# Rodar com timeout padrão de 1800 s, ou 30 minutos:
# julia --project=. rodar_um_madnlp.jl jump/bearing_400_jump.jl
#
# Rodar com timeout de 600 s, ou 10 minutos:
# julia --project=. rodar_um_madnlp.jl jump/bearing_400_jump.jl 600
#
# Rodar com timeout de 3600 s, ou 1 hora:
# julia --project=. rodar_um_madnlp.jl jump/bearing_400_jump.jl 3600
# ============================================================

Base.exit_on_sigint(false)

if length(ARGS) < 1
    error("Use assim: julia --project=. rodar_um_madnlp.jl caminho/do/modelo.jl [timeout_s]")
end

arquivo = ARGS[1]
modelo_nome = splitext(basename(arquivo))[1]

# Timeout em segundos.
# Se não informar no terminal, usa 1800 s = 30 minutos.
TIMEOUT_S = length(ARGS) >= 2 ? parse(Float64, ARGS[2]) : 1800.0

MAX_ITER = 3000
TOL = 1e-7

pasta_logs = "logs_madnlp_simples"
mkpath(pasta_logs)

log_madnlp = joinpath(pasta_logs, modelo_nome * "_madnlp.log")

csv_resumo = "resultado_madnlp_simples.csv"
csv_iteracoes = "iteracoes_madnlp_simples.csv"

# ============================================================
# FUNÇÕES AUXILIARES
# ============================================================

function csv_escape(x)
    s = string(x)
    s = replace(s, "\"" => "\"\"")
    return "\"" * s * "\""
end

function adicionar_linha_csv(caminho, cabecalho, valores)
    novo = !isfile(caminho)

    open(caminho, "a") do io
        if novo
            println(io, join(csv_escape.(cabecalho), ","))
        end
        println(io, join(csv_escape.(valores), ","))
    end
end

function parse_float_token(tok)
    tok = strip(string(tok))

    if tok == "" || tok == "-"
        return NaN
    end

    tok = replace(tok, "D" => "E")
    tok = replace(tok, "d" => "E")

    # Remove letras finais do tipo:
    # 9.90e-01f
    # 1.00e+00h
    tok = replace(tok, r"(?<=[0-9])([A-Za-z]+)$" => "")

    v = tryparse(Float64, tok)
    return isnothing(v) ? NaN : v
end

function parse_int_token(tok)
    tok = replace(string(tok), "r" => "")
    v = tryparse(Int, tok)
    return isnothing(v) ? -1 : v
end

function parse_numero_linha(texto::String, label::String)
    for linha in split(texto, '\n')
        if occursin(label, linha)
            nums = collect(eachmatch(r"[-+]?\d*\.?\d+(?:[eEdD][-+]?\d+)?", linha))
            if !isempty(nums)
                return replace(nums[end].match, "D" => "E")
            end
        end
    end
    return ""
end

function safe_string(f; default = "")
    try
        v = f()
        return isnothing(v) ? default : string(v)
    catch
        return default
    end
end

function safe_float(f; default = NaN)
    try
        v = f()
        if isnothing(v)
            return default
        end
        return v
    catch
        return default
    end
end

function encurtar_erro(s::String, n::Int = 2500)
    s = replace(s, "\n" => " | ")
    return length(s) > n ? first(s, n) * "..." : s
end

function ler_resumo_log_madnlp(log_path)
    dados = Dict{String, String}()

    if !isfile(log_path)
        return dados
    end

    texto = read(log_path, String)

    dados["madnlp_iterations"] =
        parse_numero_linha(texto, "Number of Iterations")

    if dados["madnlp_iterations"] == ""
        dados["madnlp_iterations"] =
            parse_numero_linha(texto, "Number of iterations")
    end

    dados["madnlp_objective_final_log"] =
        parse_numero_linha(texto, "Objective")

    dados["madnlp_dual_infeasibility"] =
        parse_numero_linha(texto, "Dual infeasibility")

    dados["madnlp_constraint_violation"] =
        parse_numero_linha(texto, "Constraint violation")

    dados["madnlp_variable_bound_violation"] =
        parse_numero_linha(texto, "Variable bound violation")

    dados["madnlp_complementarity"] =
        parse_numero_linha(texto, "Complementarity")

    dados["madnlp_overall_nlp_error"] =
        parse_numero_linha(texto, "Overall NLP error")

    dados["madnlp_total_seconds"] =
        parse_numero_linha(texto, "Total seconds")

    dados["madnlp_jacobian_nnz"] =
        parse_numero_linha(texto, "Number of nonzeros in constraint Jacobian")

    dados["madnlp_hessian_nnz"] =
        parse_numero_linha(texto, "Number of nonzeros in Lagrangian Hessian")

    return dados
end

function salvar_iteracoes_madnlp(log_path, arquivo, modelo_nome, csv_iteracoes)
    if !isfile(log_path)
        println("Log do MadNLP não encontrado para extrair iterações.")
        return
    end

    cabecalho = [
        "arquivo",
        "modelo",
        "solver",
        "iter",
        "restoration_phase",
        "objective",
        "inf_pr",
        "inf_du",
        "lg_mu",
        "d_norm",
        "regularization",
        "alpha_du",
        "alpha_pr",
        "step_type",
        "ls",
        "raw_line"
    ]

    for linha in eachline(log_path)
        s = strip(linha)

        # Linhas de iteração normalmente começam com número:
        # 0
        # 1
        # 12
        # ou 12r no restoration phase
        if !occursin(r"^\d+r?\s+", s)
            continue
        end

        partes = split(s)

        if length(partes) < 4
            continue
        end

        iter_token = partes[1]
        restoration = occursin("r", iter_token)

        iter = parse_int_token(iter_token)

        objective = length(partes) >= 2 ? parse_float_token(partes[2]) : NaN
        inf_pr    = length(partes) >= 3 ? parse_float_token(partes[3]) : NaN
        inf_du    = length(partes) >= 4 ? parse_float_token(partes[4]) : NaN
        lg_mu     = length(partes) >= 5 ? parse_float_token(partes[5]) : NaN
        d_norm    = length(partes) >= 6 ? parse_float_token(partes[6]) : NaN

        # Em alguns logs essa coluna pode ser lg(rg), regularização ou algo similar.
        regularization = length(partes) >= 7 ? parse_float_token(partes[7]) : NaN

        alpha_du = length(partes) >= 8 ? parse_float_token(partes[8]) : NaN
        alpha_pr = length(partes) >= 9 ? parse_float_token(partes[9]) : NaN

        step_type_match = length(partes) >= 9 ? match(r"(?<=[0-9])([A-Za-z]+)$", partes[9]) : nothing
        step_type = isnothing(step_type_match) ? "" : step_type_match.match

        ls = length(partes) >= 10 ? partes[10] : ""

        valores = [
            arquivo,
            modelo_nome,
            "MadNLP",
            iter,
            restoration,
            objective,
            inf_pr,
            inf_du,
            lg_mu,
            d_norm,
            regularization,
            alpha_du,
            alpha_pr,
            step_type,
            ls,
            s
        ]

        adicionar_linha_csv(csv_iteracoes, cabecalho, valores)
    end
end

# ============================================================
# CARREGAMENTO DO MODELO
# ============================================================

println("Carregando arquivo: ", arquivo)

erro_include = ""
modelo_carregado = false

try
    include(arquivo)
    global modelo_carregado = true
catch e
    global erro_include = encurtar_erro(sprint(showerror, e, catch_backtrace()))
end

if !modelo_carregado
    println("Erro ao carregar o arquivo.")
    println(erro_include)

    cabecalho_resumo = [
        "arquivo",
        "modelo",
        "solver",
        "status_execucao",
        "status",
        "status_primal",
        "status_dual",
        "raw_status",
        "objetivo",
        "tempo_solver_s",
        "tempo_total_s",
        "variaveis",
        "restricoes_sem_bounds",
        "restricoes_com_bounds",
        "max_iter",
        "tol",
        "timeout_s",
        "deu_timeout",
        "erro_include",
        "erro_solver",
        "madnlp_iterations",
        "madnlp_objective_final_log",
        "madnlp_dual_infeasibility",
        "madnlp_constraint_violation",
        "madnlp_variable_bound_violation",
        "madnlp_complementarity",
        "madnlp_overall_nlp_error",
        "madnlp_total_seconds",
        "madnlp_jacobian_nnz",
        "madnlp_hessian_nnz",
        "log_madnlp"
    ]

    valores_resumo = [
        arquivo,
        modelo_nome,
        "MadNLP",
        "ERRO_INCLUDE",
        "",
        "",
        "",
        "",
        NaN,
        NaN,
        NaN,
        "",
        "",
        "",
        MAX_ITER,
        TOL,
        TIMEOUT_S,
        false,
        erro_include,
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        log_madnlp
    ]

    adicionar_linha_csv(csv_resumo, cabecalho_resumo, valores_resumo)
    exit()
end

if !@isdefined(model)
    erro_include = "O arquivo foi carregado, mas não criou uma variável chamada `model`."

    println(erro_include)

    cabecalho_resumo = [
        "arquivo",
        "modelo",
        "solver",
        "status_execucao",
        "status",
        "status_primal",
        "status_dual",
        "raw_status",
        "objetivo",
        "tempo_solver_s",
        "tempo_total_s",
        "variaveis",
        "restricoes_sem_bounds",
        "restricoes_com_bounds",
        "max_iter",
        "tol",
        "timeout_s",
        "deu_timeout",
        "erro_include",
        "erro_solver",
        "madnlp_iterations",
        "madnlp_objective_final_log",
        "madnlp_dual_infeasibility",
        "madnlp_constraint_violation",
        "madnlp_variable_bound_violation",
        "madnlp_complementarity",
        "madnlp_overall_nlp_error",
        "madnlp_total_seconds",
        "madnlp_jacobian_nnz",
        "madnlp_hessian_nnz",
        "log_madnlp"
    ]

    valores_resumo = [
        arquivo,
        modelo_nome,
        "MadNLP",
        "ERRO_SEM_MODEL",
        "",
        "",
        "",
        "",
        NaN,
        NaN,
        NaN,
        "",
        "",
        "",
        MAX_ITER,
        TOL,
        TIMEOUT_S,
        false,
        erro_include,
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        log_madnlp
    ]

    adicionar_linha_csv(csv_resumo, cabecalho_resumo, valores_resumo)
    exit()
end

println("Arquivo carregado.")

nvar = num_variables(model)
ncons_sem_bounds = num_constraints(model; count_variable_in_set_constraints=false)
ncons_com_bounds = num_constraints(model; count_variable_in_set_constraints=true)

println("Variáveis: ", nvar)
println("Restrições sem bounds: ", ncons_sem_bounds)
println("Restrições com bounds: ", ncons_com_bounds)

# ============================================================
# CONFIGURAÇÃO DO MADNLP
# ============================================================

set_optimizer(model, MadNLP.Optimizer)

set_optimizer_attribute(model, "max_iter", MAX_ITER)
set_optimizer_attribute(model, "tol", TOL)

# INFO mostra as iterações no log.
set_optimizer_attribute(model, "print_level", MadNLP.INFO)

println("Rodando MadNLP...")
println("Timeout: ", TIMEOUT_S, " s")
println("Log será salvo em: ", log_madnlp)

# ============================================================
# EXECUÇÃO COM TIMEOUT
# ============================================================

deu_timeout = false
erro_solver = ""

tempo_total_inicio = time()

timer = Timer(TIMEOUT_S) do t
    global deu_timeout = true
    @warn "TIMEOUT atingido. Interrompendo MadNLP..."
    ccall(:raise, Cint, (Cint,), 2)
end

try
    open(log_madnlp, "w") do io
        redirect_stdout(io) do
            redirect_stderr(io) do
                optimize!(model)
            end
        end
    end
catch e
    if e isa InterruptException
        deu_timeout = true
        erro_solver = "TIMEOUT atingido após $(TIMEOUT_S) segundos."
    else
        erro_solver = encurtar_erro(sprint(showerror, e, catch_backtrace()))
    end
finally
    close(timer)
end

tempo_total = time() - tempo_total_inicio

# ============================================================
# COLETA DOS RESULTADOS
# ============================================================

status_execucao = deu_timeout ? "TIMEOUT" : (erro_solver == "" ? "OK" : "ERRO_SOLVER")

status = safe_string(() -> termination_status(model))
status_primal = safe_string(() -> primal_status(model))
status_dual = safe_string(() -> dual_status(model))
raw_status_str = safe_string(() -> raw_status(model))

if deu_timeout
    status = "TIMEOUT"
end

objetivo = safe_float(() -> has_values(model) ? objective_value(model) : NaN)

tempo_solver = safe_float(() -> solve_time(model); default = tempo_total)

dados_log = ler_resumo_log_madnlp(log_madnlp)

println()
println("===== RESULTADO MADNLP =====")
println("Arquivo: ", arquivo)
println("Status execução: ", status_execucao)
println("Status: ", status)
println("Status primal: ", status_primal)
println("Status dual: ", status_dual)
println("Objetivo: ", objetivo)
println("Tempo solver/JuMP: ", tempo_solver, " s")
println("Tempo total medido: ", tempo_total, " s")
println("Timeout: ", deu_timeout)
println("Log MadNLP: ", log_madnlp)

if erro_solver != ""
    println("Erro solver: ", erro_solver)
end

# ============================================================
# CSV 1: RESUMO FINAL
# ============================================================

cabecalho_resumo = [
    "arquivo",
    "modelo",
    "solver",
    "status_execucao",
    "status",
    "status_primal",
    "status_dual",
    "raw_status",
    "objetivo",
    "tempo_solver_s",
    "tempo_total_s",
    "variaveis",
    "restricoes_sem_bounds",
    "restricoes_com_bounds",
    "max_iter",
    "tol",
    "timeout_s",
    "deu_timeout",
    "erro_include",
    "erro_solver",
    "madnlp_iterations",
    "madnlp_objective_final_log",
    "madnlp_dual_infeasibility",
    "madnlp_constraint_violation",
    "madnlp_variable_bound_violation",
    "madnlp_complementarity",
    "madnlp_overall_nlp_error",
    "madnlp_total_seconds",
    "madnlp_jacobian_nnz",
    "madnlp_hessian_nnz",
    "log_madnlp"
]

valores_resumo = [
    arquivo,
    modelo_nome,
    "MadNLP",
    status_execucao,
    status,
    status_primal,
    status_dual,
    raw_status_str,
    objetivo,
    tempo_solver,
    tempo_total,
    nvar,
    ncons_sem_bounds,
    ncons_com_bounds,
    MAX_ITER,
    TOL,
    TIMEOUT_S,
    deu_timeout,
    erro_include,
    erro_solver,
    get(dados_log, "madnlp_iterations", ""),
    get(dados_log, "madnlp_objective_final_log", ""),
    get(dados_log, "madnlp_dual_infeasibility", ""),
    get(dados_log, "madnlp_constraint_violation", ""),
    get(dados_log, "madnlp_variable_bound_violation", ""),
    get(dados_log, "madnlp_complementarity", ""),
    get(dados_log, "madnlp_overall_nlp_error", ""),
    get(dados_log, "madnlp_total_seconds", ""),
    get(dados_log, "madnlp_jacobian_nnz", ""),
    get(dados_log, "madnlp_hessian_nnz", ""),
    log_madnlp
]

adicionar_linha_csv(csv_resumo, cabecalho_resumo, valores_resumo)

# ============================================================
# CSV 2: ITERAÇÕES
# ============================================================

salvar_iteracoes_madnlp(log_madnlp, arquivo, modelo_nome, csv_iteracoes)

println()
println("Resumo salvo em: ", csv_resumo)
println("Iterações salvas em: ", csv_iteracoes)
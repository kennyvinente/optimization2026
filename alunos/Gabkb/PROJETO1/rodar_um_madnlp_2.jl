using JuMP
using MadNLP
using Printf

# ============================================================
# USO:
# julia --project=. rodar_um_madnlp_2.jl jump_2/bearing_400_jump.jl
# ou, se passar só o nome do arquivo:
# julia --project=. rodar_um_madnlp_2.jl bearing_400_jump.jl
# ============================================================

if length(ARGS) < 1
    error("Use assim: julia --project=. rodar_um_madnlp_2.jl caminho/do/modelo.jl")
end

entrada = ARGS[1]

# Se você passar apenas o nome do arquivo, ele procura dentro de jump_2.
arquivo = dirname(entrada) == "" ? joinpath("jump_2", entrada) : entrada

modelo_nome = splitext(basename(arquivo))[1]

pasta_logs = "logs_madnlp_simples_2"
mkpath(pasta_logs)

log_madnlp = joinpath(pasta_logs, modelo_nome * "_madnlp_2.log")

csv_resumo = "resultado_madnlp_simples_2.csv"
csv_iteracoes = "iteracoes_madnlp_simples_2.csv"

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

    # Remove letras finais do tipo 9.90e-01f ou 1.00e+00h
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

function ler_resumo_log_madnlp(log_path)
    dados = Dict{String, String}()

    if !isfile(log_path)
        return dados
    end

    texto = read(log_path, String)

    dados["madnlp_iterations"] = parse_numero_linha(texto, "Number of Iterations")
    if dados["madnlp_iterations"] == ""
        dados["madnlp_iterations"] = parse_numero_linha(texto, "Number of iterations")
    end

    dados["madnlp_objective_final_log"] = parse_numero_linha(texto, "Objective")
    dados["madnlp_dual_infeasibility"] = parse_numero_linha(texto, "Dual infeasibility")
    dados["madnlp_constraint_violation"] = parse_numero_linha(texto, "Constraint violation")
    dados["madnlp_variable_bound_violation"] = parse_numero_linha(texto, "Variable bound violation")
    dados["madnlp_complementarity"] = parse_numero_linha(texto, "Complementarity")
    dados["madnlp_overall_nlp_error"] = parse_numero_linha(texto, "Overall NLP error")
    dados["madnlp_total_seconds"] = parse_numero_linha(texto, "Total seconds")
    dados["madnlp_jacobian_nnz"] = parse_numero_linha(texto, "Number of nonzeros in constraint Jacobian")
    dados["madnlp_hessian_nnz"] = parse_numero_linha(texto, "Number of nonzeros in Lagrangian Hessian")

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
        regularization = length(partes) >= 7 ? parse_float_token(partes[7]) : NaN
        alpha_du = length(partes) >= 8 ? parse_float_token(partes[8]) : NaN
        alpha_pr = length(partes) >= 9 ? parse_float_token(partes[9]) : NaN

        step_type_match = length(partes) >= 9 ? match(r"[A-Za-z]+$", partes[9]) : nothing
        step_type = isnothing(step_type_match) ? "" : step_type_match.match

        ls = length(partes) >= 10 ? partes[10] : ""

        valores = [
            arquivo,
            modelo_nome,
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
# EXECUÇÃO DO MODELO
# ============================================================

println("Carregando arquivo: ", arquivo)

include(arquivo)

if !@isdefined(model)
    error("O arquivo foi carregado, mas não criou uma variável chamada `model`.")
end

println("Modelo carregado.")

nvar = num_variables(model)
ncons_sem_bounds = num_constraints(model; count_variable_in_set_constraints=false)
ncons_com_bounds = num_constraints(model; count_variable_in_set_constraints=true)

println("Variáveis: ", nvar)
println("Restrições sem bounds: ", ncons_sem_bounds)
println("Restrições com bounds: ", ncons_com_bounds)

set_optimizer(model, MadNLP.Optimizer)

set_optimizer_attribute(model, "max_iter", 3000)
set_optimizer_attribute(model, "tol", 1e-7)

# MadNLP imprime no stdout/stderr; por isso o log é capturado com redirect.
# INFO normalmente mostra a tabela de iterações.
set_optimizer_attribute(model, "print_level", MadNLP.INFO)

println("Rodando MadNLP...")
println("Log MadNLP: ", log_madnlp)

tempo_inicio = time()
erro_solver = ""

try
    open(log_madnlp, "w") do io
        redirect_stdout(io) do
            redirect_stderr(io) do
                optimize!(model)
            end
        end
    end
catch e
    erro_solver = replace(sprint(showerror, e, catch_backtrace()), "\n" => " | ")
end

tempo_total = time() - tempo_inicio

status = erro_solver == "" ? string(termination_status(model)) : "ERRO_SOLVER"
status_primal = erro_solver == "" ? string(primal_status(model)) : ""
status_dual = erro_solver == "" ? string(dual_status(model)) : ""
raw_status_str = erro_solver == "" ? string(raw_status(model)) : ""

objetivo = erro_solver == "" && has_values(model) ? objective_value(model) : NaN
tempo_jump = erro_solver == "" ? solve_time(model) : NaN

dados_log = ler_resumo_log_madnlp(log_madnlp)

println()
println("===== RESULTADO =====")
println("Arquivo: ", arquivo)
println("Status: ", status)
println("Status primal: ", status_primal)
println("Status dual: ", status_dual)
println("Objetivo: ", objetivo)
println("Tempo JuMP: ", tempo_jump, " s")
println("Tempo total: ", tempo_total, " s")
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
    "status",
    "status_primal",
    "status_dual",
    "raw_status",
    "objetivo",
    "tempo_jump_s",
    "tempo_total_s",
    "variaveis",
    "restricoes_sem_bounds",
    "restricoes_com_bounds",
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
    "erro_solver",
    "log_madnlp"
]

valores_resumo = [
    arquivo,
    modelo_nome,
    status,
    status_primal,
    status_dual,
    raw_status_str,
    objetivo,
    tempo_jump,
    tempo_total,
    nvar,
    ncons_sem_bounds,
    ncons_com_bounds,
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
    erro_solver,
    log_madnlp
]

adicionar_linha_csv(csv_resumo, cabecalho_resumo, valores_resumo)

# ============================================================
# CSV 2: ITERAÇÕES DO MADNLP
# ============================================================

salvar_iteracoes_madnlp(log_madnlp, arquivo, modelo_nome, csv_iteracoes)

println()
println("Resumo salvo em: ", csv_resumo)
println("Iterações salvas em: ", csv_iteracoes)

using JuMP
using Ipopt
using Printf

# ============================================================
# USO:
# julia --project=. rodar_um_ipopt_2.jl jump_2/bearing_400_jump.jl
# ou, se passar só o nome do arquivo:
# julia --project=. rodar_um_ipopt_2.jl bearing_400_jump.jl
# ============================================================

if length(ARGS) < 1
    error("Use assim: julia --project=. rodar_um_ipopt_2.jl caminho/do/modelo.jl")
end

entrada = ARGS[1]

# Se você passar apenas o nome do arquivo, ele procura dentro de jump_2.
# Exemplo: julia --project=. rodar_um_ipopt_2.jl bearing_400_jump.jl
# vira automaticamente: jump_2/bearing_400_jump.jl
arquivo = dirname(entrada) == "" ? joinpath("jump_2", entrada) : entrada

modelo_nome = splitext(basename(arquivo))[1]

pasta_logs = "logs_ipopt_simples_2"
mkpath(pasta_logs)

log_ipopt = joinpath(pasta_logs, modelo_nome * "_ipopt_2.log")

csv_resumo = "resultado_ipopt_simples_2.csv"
csv_iteracoes = "iteracoes_ipopt_simples_2.csv"

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

    # Ipopt pode usar D em vez de E em alguns logs
    tok = replace(tok, "D" => "E")
    tok = replace(tok, "d" => "E")

    # Remove apenas letras finais do tipo:
    # 9.90e-01f
    # 1.00e+00h
    # 3.2e-04F
    tok = replace(tok, r"(?<=[0-9])([A-Za-z]+)$" => "")

    v = tryparse(Float64, tok)
    return isnothing(v) ? NaN : v
end

function parse_int_token(tok)
    tok = replace(tok, "r" => "")
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

function ler_resumo_log_ipopt(log_path)
    dados = Dict{String, String}()

    if !isfile(log_path)
        return dados
    end

    texto = read(log_path, String)

    dados["ipopt_iterations"] =
        parse_numero_linha(texto, "Number of Iterations")

    dados["ipopt_objective_final_log"] =
        parse_numero_linha(texto, "Objective")

    dados["ipopt_dual_infeasibility"] =
        parse_numero_linha(texto, "Dual infeasibility")

    dados["ipopt_constraint_violation"] =
        parse_numero_linha(texto, "Constraint violation")

    dados["ipopt_variable_bound_violation"] =
        parse_numero_linha(texto, "Variable bound violation")

    dados["ipopt_complementarity"] =
        parse_numero_linha(texto, "Complementarity")

    dados["ipopt_overall_nlp_error"] =
        parse_numero_linha(texto, "Overall NLP error")

    dados["ipopt_objective_evaluations"] =
        parse_numero_linha(texto, "Number of objective function evaluations")

    dados["ipopt_gradient_evaluations"] =
        parse_numero_linha(texto, "Number of objective gradient evaluations")

    dados["ipopt_eq_constraint_evaluations"] =
        parse_numero_linha(texto, "Number of equality constraint evaluations")

    dados["ipopt_ineq_constraint_evaluations"] =
        parse_numero_linha(texto, "Number of inequality constraint evaluations")

    dados["ipopt_eq_jacobian_evaluations"] =
        parse_numero_linha(texto, "Number of equality constraint Jacobian evaluations")

    dados["ipopt_ineq_jacobian_evaluations"] =
        parse_numero_linha(texto, "Number of inequality constraint Jacobian evaluations")

    dados["ipopt_hessian_evaluations"] =
        parse_numero_linha(texto, "Number of Lagrangian Hessian evaluations")

    dados["ipopt_total_seconds"] =
        parse_numero_linha(texto, "Total seconds in IPOPT")

    return dados
end

function salvar_iteracoes_ipopt(log_path, arquivo, modelo_nome, csv_iteracoes)
    if !isfile(log_path)
        println("Log do Ipopt não encontrado para extrair iterações.")
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
        "lg_rg",
        "alpha_du",
        "alpha_pr",
        "step_type",
        "ls"
    ]

    for linha in eachline(log_path)
        s = strip(linha)

        # Linhas de iteração começam com número:
        # 0, 1, 2, ...
        # ou, em alguns casos, 12r no modo restoration.
        if !occursin(r"^\d+r?\s+", s)
            continue
        end

        partes = split(s)

        if length(partes) < 10
            continue
        end

        iter_token = partes[1]
        restoration = occursin("r", iter_token)

        iter = parse_int_token(iter_token)
        objective = parse_float_token(partes[2])
        inf_pr = parse_float_token(partes[3])
        inf_du = parse_float_token(partes[4])
        lg_mu = parse_float_token(partes[5])
        d_norm = parse_float_token(partes[6])
        lg_rg = parse_float_token(partes[7])
        alpha_du = parse_float_token(partes[8])
        alpha_pr = parse_float_token(partes[9])

        # alpha_pr pode vir como 9.90e-01f, 1.00e+00h etc.
        step_type_match = match(r"[A-Za-z]+$", partes[9])
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
            lg_rg,
            alpha_du,
            alpha_pr,
            step_type,
            ls
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

set_optimizer(model, Ipopt.Optimizer)


set_optimizer_attribute(model, "print_level", 0)
set_optimizer_attribute(model, "file_print_level", 5)
set_optimizer_attribute(model, "output_file", log_ipopt)

set_optimizer_attribute(model, "max_iter", 3000)
set_optimizer_attribute(model, "max_wall_time", 1800.0)

set_optimizer_attribute(model, "tol", 1e-7)
set_optimizer_attribute(model, "acceptable_tol", 1e-6)

set_optimizer_attribute(model, "mu_strategy", "adaptive")
set_optimizer_attribute(model, "hessian_approximation", "limited-memory")

println("Rodando Ipopt...")
optimize!(model)

status = string(termination_status(model))
status_primal = string(primal_status(model))
status_dual = string(dual_status(model))
raw_status_str = string(raw_status(model))

objetivo = has_values(model) ? objective_value(model) : NaN
tempo_jump = solve_time(model)

dados_log = ler_resumo_log_ipopt(log_ipopt)

println()
println("===== RESULTADO =====")
println("Arquivo: ", arquivo)
println("Status: ", status)
println("Status primal: ", status_primal)
println("Status dual: ", status_dual)
println("Objetivo: ", objetivo)
println("Tempo JuMP: ", tempo_jump, " s")
println("Log Ipopt: ", log_ipopt)

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
    "variaveis",
    "restricoes_sem_bounds",
    "restricoes_com_bounds",
    "ipopt_iterations",
    "ipopt_objective_final_log",
    "ipopt_dual_infeasibility",
    "ipopt_constraint_violation",
    "ipopt_variable_bound_violation",
    "ipopt_complementarity",
    "ipopt_overall_nlp_error",
    "ipopt_objective_evaluations",
    "ipopt_gradient_evaluations",
    "ipopt_eq_constraint_evaluations",
    "ipopt_ineq_constraint_evaluations",
    "ipopt_eq_jacobian_evaluations",
    "ipopt_ineq_jacobian_evaluations",
    "ipopt_hessian_evaluations",
    "ipopt_total_seconds",
    "log_ipopt"
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
    nvar,
    ncons_sem_bounds,
    ncons_com_bounds,
    get(dados_log, "ipopt_iterations", ""),
    get(dados_log, "ipopt_objective_final_log", ""),
    get(dados_log, "ipopt_dual_infeasibility", ""),
    get(dados_log, "ipopt_constraint_violation", ""),
    get(dados_log, "ipopt_variable_bound_violation", ""),
    get(dados_log, "ipopt_complementarity", ""),
    get(dados_log, "ipopt_overall_nlp_error", ""),
    get(dados_log, "ipopt_objective_evaluations", ""),
    get(dados_log, "ipopt_gradient_evaluations", ""),
    get(dados_log, "ipopt_eq_constraint_evaluations", ""),
    get(dados_log, "ipopt_ineq_constraint_evaluations", ""),
    get(dados_log, "ipopt_eq_jacobian_evaluations", ""),
    get(dados_log, "ipopt_ineq_jacobian_evaluations", ""),
    get(dados_log, "ipopt_hessian_evaluations", ""),
    get(dados_log, "ipopt_total_seconds", ""),
    log_ipopt
]

adicionar_linha_csv(csv_resumo, cabecalho_resumo, valores_resumo)

# ============================================================
# CSV 2: ITERAÇÕES DO IPOPT
# ============================================================

salvar_iteracoes_ipopt(log_ipopt, arquivo, modelo_nome, csv_iteracoes)

println()
println("Resumo salvo em: ", csv_resumo)
println("Iterações salvas em: ", csv_iteracoes)
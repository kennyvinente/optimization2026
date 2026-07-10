using JuMP
using NLopt
using Printf

# ============================================================
# USO:
# julia --project=. rodar_um_nlopt_2.jl jump_2/ex6_1_1_jump.jl
# ou passando so o nome:
# julia --project=. rodar_um_nlopt_2.jl ex6_1_1_jump.jl
#
# Algoritmo padrao: :LD_SLSQP
# Opcional:
# julia --project=. rodar_um_nlopt_2.jl modelo.jl LD_SLSQP
# ============================================================

if length(ARGS) < 1
    error("Use assim: julia --project=. rodar_um_nlopt_2.jl caminho/do/modelo.jl [algoritmo]")
end

entrada = ARGS[1]
arquivo = dirname(entrada) == "" ? joinpath("jump_2", entrada) : entrada
modelo_nome = splitext(basename(arquivo))[1]

ALGORITMO = length(ARGS) >= 2 ? Symbol(ARGS[2]) : :LD_SLSQP
MAXEVAL = 3000
MAXTIME = 1800.0
TOL = 1e-7
CONSTR_TOL = 1e-7

pasta_logs = "logs_nlopt_simples_2"
mkpath(pasta_logs)
log_nlopt = joinpath(pasta_logs, modelo_nome * "_nlopt_2.log")

csv_resumo = "resultado_nlopt_simples_2.csv"

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

function safe_string(f; default="")
    try
        v = f()
        return isnothing(v) ? default : string(v)
    catch e
        return default
    end
end

function safe_float(f; default=NaN)
    try
        v = f()
        return isnothing(v) ? default : Float64(v)
    catch e
        return default
    end
end

function encurtar_erro(s::String, n::Int=2500)
    s = replace(s, "\n" => " | ")
    return length(s) > n ? first(s, n) * "..." : s
end

println("Carregando arquivo: ", arquivo)

erro_include = ""
erro_solver = ""
modelo_carregado = false

try
    include(arquivo)
    global modelo_carregado = true
catch e
    global erro_include = encurtar_erro(sprint(showerror, e, catch_backtrace()))
end

if !modelo_carregado
    println("Erro ao carregar modelo: ", erro_include)
    cabecalho = ["arquivo", "modelo", "solver", "algoritmo", "status_execucao", "status", "status_primal", "status_dual", "raw_status", "objetivo", "tempo_jump_s", "variaveis", "restricoes_sem_bounds", "restricoes_com_bounds", "maxeval", "maxtime", "tol", "constrtol_abs", "erro_include", "erro_solver", "log"]
    valores = [arquivo, modelo_nome, "NLopt", string(ALGORITMO), "ERRO_INCLUDE", "", "", "", "", NaN, NaN, "", "", "", MAXEVAL, MAXTIME, TOL, CONSTR_TOL, erro_include, "", log_nlopt]
    adicionar_linha_csv(csv_resumo, cabecalho, valores)
    exit()
end

if !@isdefined(model)
    error("O arquivo foi carregado, mas nao criou uma variavel chamada `model`.")
end

println("Modelo carregado.")
nvar = num_variables(model)
ncons_sem_bounds = num_constraints(model; count_variable_in_set_constraints=false)
ncons_com_bounds = num_constraints(model; count_variable_in_set_constraints=true)

println("Variaveis: ", nvar)
println("Restricoes sem bounds: ", ncons_sem_bounds)
println("Restricoes com bounds: ", ncons_com_bounds)

set_optimizer(model, NLopt.Optimizer)
set_attribute(model, "algorithm", ALGORITMO)
set_attribute(model, "maxeval", MAXEVAL)
set_attribute(model, "maxtime", MAXTIME)
set_attribute(model, "xtol_rel", TOL)
set_attribute(model, "ftol_rel", TOL)
set_attribute(model, "constrtol_abs", CONSTR_TOL)

println("Rodando NLopt com algoritmo ", ALGORITMO, "...")

tempo_inicio = time()
try
    open(log_nlopt, "w") do io
        redirect_stdout(io) do
            redirect_stderr(io) do
                JuMP.optimize!(model)
            end
        end
    end
catch e
    global erro_solver = encurtar_erro(sprint(showerror, e, catch_backtrace()))
end
tempo_total = time() - tempo_inicio

status_execucao = erro_solver == "" ? "OK" : "ERRO_SOLVER"
status = safe_string(() -> termination_status(model))
status_primal = safe_string(() -> primal_status(model))
status_dual = safe_string(() -> dual_status(model))
raw_status_str = safe_string(() -> raw_status(model))
objetivo = safe_float(() -> has_values(model) ? objective_value(model) : NaN)
tempo_jump = safe_float(() -> solve_time(model); default=tempo_total)

println()
println("===== RESULTADO NLOPT =====")
println("Arquivo: ", arquivo)
println("Algoritmo: ", ALGORITMO)
println("Status execucao: ", status_execucao)
println("Status: ", status)
println("Objetivo: ", objetivo)
println("Tempo JuMP: ", tempo_jump, " s")
println("Log: ", log_nlopt)
if erro_solver != ""
    println("Erro solver: ", erro_solver)
end

cabecalho = ["arquivo", "modelo", "solver", "algoritmo", "status_execucao", "status", "status_primal", "status_dual", "raw_status", "objetivo", "tempo_jump_s", "variaveis", "restricoes_sem_bounds", "restricoes_com_bounds", "maxeval", "maxtime", "tol", "constrtol_abs", "erro_include", "erro_solver", "log"]
valores = [arquivo, modelo_nome, "NLopt", string(ALGORITMO), status_execucao, status, status_primal, status_dual, raw_status_str, objetivo, tempo_jump, nvar, ncons_sem_bounds, ncons_com_bounds, MAXEVAL, MAXTIME, TOL, CONSTR_TOL, erro_include, erro_solver, log_nlopt]
adicionar_linha_csv(csv_resumo, cabecalho, valores)

println("Resumo salvo em: ", csv_resumo)

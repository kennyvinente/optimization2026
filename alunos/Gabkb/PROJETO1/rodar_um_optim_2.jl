using JuMP
using Optim
using Printf

# ============================================================
# USO:
# julia --project=. rodar_um_optim_2.jl jump_2/exemplo_jump.jl
# ou passando so o nome:
# julia --project=. rodar_um_optim_2.jl exemplo_jump.jl
#
# ATENCAO: Optim.jl via JuMP e mais indicado para modelos sem
# restricoes gerais. Modelos GAMS com igualdades/desigualdades podem
# retornar erro INVALID_MODEL/ERRO_SOLVER.
# ============================================================

if length(ARGS) < 1
    error("Use assim: julia --project=. rodar_um_optim_2.jl caminho/do/modelo.jl")
end

entrada = ARGS[1]
arquivo = dirname(entrada) == "" ? joinpath("jump_2", entrada) : entrada
modelo_nome = splitext(basename(arquivo))[1]

MAX_ITER = 3000
pasta_logs = "logs_optim_simples_2"
mkpath(pasta_logs)
log_optim = joinpath(pasta_logs, modelo_nome * "_optim_2.log")
csv_resumo = "resultado_optim_simples_2.csv"

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
    cabecalho = ["arquivo", "modelo", "solver", "metodo", "status_execucao", "status", "status_primal", "status_dual", "raw_status", "objetivo", "tempo_jump_s", "variaveis", "restricoes_sem_bounds", "restricoes_com_bounds", "max_iter", "erro_include", "erro_solver", "log"]
    valores = [arquivo, modelo_nome, "Optim", "LBFGS", "ERRO_INCLUDE", "", "", "", "", NaN, NaN, "", "", "", MAX_ITER, erro_include, "", log_optim]
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

set_optimizer(model, Optim.Optimizer)
set_optimizer_attribute(model, "method", Optim.LBFGS())
set_optimizer_attribute(model, "iterations", MAX_ITER)

println("Rodando Optim.jl com LBFGS...")

tempo_inicio = time()
try
    open(log_optim, "w") do io
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
println("===== RESULTADO OPTIM =====")
println("Arquivo: ", arquivo)
println("Status execucao: ", status_execucao)
println("Status: ", status)
println("Objetivo: ", objetivo)
println("Tempo JuMP: ", tempo_jump, " s")
println("Log: ", log_optim)
if erro_solver != ""
    println("Erro solver: ", erro_solver)
end

cabecalho = ["arquivo", "modelo", "solver", "metodo", "status_execucao", "status", "status_primal", "status_dual", "raw_status", "objetivo", "tempo_jump_s", "variaveis", "restricoes_sem_bounds", "restricoes_com_bounds", "max_iter", "erro_include", "erro_solver", "log"]
valores = [arquivo, modelo_nome, "Optim", "LBFGS", status_execucao, status, status_primal, status_dual, raw_status_str, objetivo, tempo_jump, nvar, ncons_sem_bounds, ncons_com_bounds, MAX_ITER, erro_include, erro_solver, log_optim]
adicionar_linha_csv(csv_resumo, cabecalho, valores)

println("Resumo salvo em: ", csv_resumo)

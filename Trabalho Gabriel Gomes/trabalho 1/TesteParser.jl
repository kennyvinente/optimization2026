using JuMP
using Ipopt
using MadNLP
using NLopt
using CSV
using DataFrames

# ==============================================================================
# 1. MODELOS TRADUZIDOS
# ==============================================================================

function carregar_ex_10_1(optimizer)
    # Deixando explícito que o Model é do JuMP
    model = JuMP.Model(optimizer)
    
    # Variáveis
    @variable(model, x[1:11] >= 0.001)
    @constraint(model, x[11] >= 0.01)

    # Constantes
    c = [
        6.0557680362407096, 17.130768036240699, 34.020768036240703,
        5.8807680362407098, 24.687768036240701, 14.9527680362407,
        24.066768036240699, 10.6747680362407,   26.6287680362407,
        22.144768036240698
    ]

    # Restrições
    @constraint(model, sum(x[i] for i in 1:10) == x[11])
    @constraint(model, x[3] + x[7] + x[8] + 2 * x[9] + x[10] == 1)
    @constraint(model, x[4] + 2 * x[5] + x[6] + x[7] == 1)
    @constraint(model, x[1] + 2 * x[2] + 2 * x[3] + x[6] + x[10] == 2)

    # Função Objetivo 
    @objective(model, Min, sum(x[i] * (log(x[i] / x[11]) - c[i]) for i in 1:10))
    
    # Solução ótima conhecida 
    otimo_conhecido = -47.707579 
    
    return model, otimo_conhecido
end

# ==============================================================================
# 2. DICIONÁRIO E CONFIGURAÇÃO DE SOLVERS
# ==============================================================================

dicionario_instancias = Dict(
    "ex_10_1" => carregar_ex_10_1
)

solvers_para_testar = ["Ipopt", "MadNLP", "NLopt_LD_SLSQP"]

function obter_optimizer(nome_solver::String)
    if nome_solver == "Ipopt"
        return optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
    elseif nome_solver == "MadNLP"
        return optimizer_with_attributes(MadNLP.Optimizer, "print_level" => MadNLP.ERROR)
    elseif nome_solver == "NLopt_LD_SLSQP"
        return optimizer_with_attributes(NLopt.Optimizer, "algorithm" => :LD_SLSQP)
    end
end

# ==============================================================================
# 3. MOTOR DO BENCHMARK
# ==============================================================================

function executar_benchmark_nativo()
    resultados = DataFrame(Instancia=String[], Solver=String[], Status=String[], Tempo_s=Float64[], Objetivo=Float64[], Gap=Float64[])
    
    println("Iniciando Benchmark Nativo...\n")
    
    for (nome_instancia, funcao_construtora) in dicionario_instancias
        println("========================================")
        println("Resolvendo: $nome_instancia")
        
        for solver in solvers_para_testar
            try
                optimizer = obter_optimizer(solver)
                model, f_ref = funcao_construtora(optimizer)
                
                # AQUI ESTÁ A CORREÇÃO: JuMP.optimize! e JuMP.termination_status
                tempo_exec = @elapsed JuMP.optimize!(model)
                status_termino = JuMP.termination_status(model)
                
                if status_termino == MOI.OPTIMAL || status_termino == MOI.LOCALLY_SOLVED
                    f_opt = JuMP.objective_value(model)
                    gap = abs(f_opt - f_ref) / (abs(f_ref) + 1e-10)
                else
                    f_opt = NaN
                    gap = NaN
                end
                
                push!(resultados, (nome_instancia, solver, string(status_termino), tempo_exec, f_opt, gap))
                println("  ➜ $solver | Status: $status_termino | Obj: $(round(f_opt, digits=4)) | Gap: $(round(gap, digits=6))")
                
            catch e
                push!(resultados, (nome_instancia, solver, "ERRO", 0.0, NaN, NaN))
                println("  ➜ $solver | FALHA DE EXECUÇÃO. Motivo:")
                showerror(stdout, e)
                println("\n")
            end
        end
    end
    
    CSV.write("resultados_benchmark_nativo.csv", resultados)
    println("\n✔ Concluído! CSV gerado: 'resultados_benchmark_nativo.csv'.")
end

executar_benchmark_nativo()
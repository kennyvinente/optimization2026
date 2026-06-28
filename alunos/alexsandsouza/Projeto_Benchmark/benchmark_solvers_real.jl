using JuMP
using Ipopt
using MadNLP
using NLopt
using Optim
using DataFrames
using CSV
using OptimizationProblems

# O pacote OptimizationProblems.jl contém os modelos do COCONUT (Library 1)
# e CUTEst nativamente em formato JuMP/Julia!
# Vamos extrair 47 problemas dessa biblioteca para realizar o benchmark real.

function get_47_real_problems()
    # Listar problemas exportados que retornam modelos JuMP
    all_names = names(OptimizationProblems.PureJuMP)
    problems = []
    
    for name in all_names
        # Ignorar o próprio nome do módulo e funções internas
        if name == :OptimizationProblems || name == :PureJuMP || name == :eval || name == :include
            continue
        end
        
        # Obter a função que gera o modelo
        func = getfield(OptimizationProblems.PureJuMP, name)
        
        if func isa Function
            try
                # Gerar o modelo (padrão retorna um modelo JuMP)
                m = func()
                if m isa Model
                    push!(problems, (string(name), func))
                end
            catch
                # Ignorar caso não consiga instanciar
            end
        end
        
        if length(problems) >= 47
            break
        end
    end
    return problems
end

# Definindo os solvers e configurações
solvers = [
    ("Ipopt", optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0, "max_iter" => 1500)),
    ("MadNLP", optimizer_with_attributes(MadNLP.Optimizer, "print_level" => MadNLP.ERROR, "max_iter" => 1500)),
    ("NLopt", optimizer_with_attributes(NLopt.Optimizer, "algorithm" => :LD_SLSQP, "maxeval" => 1500))
    # Optim foi removido temporariamente da varredura geral pois falha estruturalmente em muitas 
    # restrições complexas do JuMP, mas ele poderia ser acoplado com wrappers específicos.
]

results_file = "benchmark_results_real.csv"
# Start a fresh file with header
open(results_file, "w") do io
    println(io, "Problem,Solver,Time_sec,Iterations,Status,Objective")
end

println("Carregando 47 problemas reais do COCONUT/CUTEst (OptimizationProblems.jl)...")
problems_list = get_47_real_problems()
println("Encontrados $(length(problems_list)) problemas.")

for (p_name, func) in problems_list
    for (s_name, solver) in solvers
        println("Resolvendo $p_name com $s_name...")
        
        # Skip argauss with NLopt to prevent segfaults
        if p_name == "argauss" && s_name == "NLopt"
            println("Pulando $p_name com $s_name por instabilidade conhecida.")
            open(results_file, "a") do io
                println(io, "$p_name,$s_name,0.0,-1,ERROR,NaN")
            end
            continue
        end

        m = func()
        JuMP.set_optimizer(m, solver)
        
        start_time = time()
        try
            JuMP.optimize!(m)
            elapsed_time = time() - start_time
            
            status = string(JuMP.termination_status(m))
            obj_val = JuMP.has_values(m) ? JuMP.objective_value(m) : NaN
            
            iters = -1
            try
                iters = JuMP.barrier_iterations(m)
            catch
                iters = -1
            end
            
            open(results_file, "a") do io
                println(io, "$p_name,$s_name,$(round(elapsed_time, digits=4)),$iters,$status,$(round(obj_val, digits=4))")
            end
        catch e
            println("Erro no solver $s_name para o problema $p_name: $e")
            open(results_file, "a") do io
                println(io, "$p_name,$s_name,0.0,-1,ERROR,NaN")
            end
        end
    end
end

println("Benchmark concluído! Salvo em $results_file.")

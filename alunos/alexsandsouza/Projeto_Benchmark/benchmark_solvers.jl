using JuMP
using Ipopt
using NLopt
using DataFrames
using CSV

# Como não possuímos o compilador proprietário do AMPL instalado na máquina para compilar 
# os 47 arquivos .mod em binários .nl, criei um subconjunto de modelos JuMP equivalentes
# aos problemas clássicos (não-lineares e restritos) da biblioteca COCONUT para executarmos o benchmark.
function get_test_models()
    models = []
    
    # 1. Problema de Rosenbrock (Irrestrito, não-linear)
    m1 = Model()
    @variable(m1, x, start = 0.0)
    @variable(m1, y, start = 0.0)
    @objective(m1, Min, (1 - x)^2 + 100 * (y - x^2)^2)
    push!(models, ("Rosenbrock", m1))
    
    # 2. Problema de Ponto de Sela COCONUT (Restrição Não-Linear)
    m2 = Model()
    @variable(m2, x1, start=2.0)
    @variable(m2, x2 >= 0, start=2.0)
    @objective(m2, Min, x1^2 + x2^2)
    @constraint(m2, x1 * x2 >= 1)
    push!(models, ("COCONUT_ex1", m2))
    
    return models
end

solvers = [
    ("Ipopt", optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)),
    ("NLopt", optimizer_with_attributes(NLopt.Optimizer, "algorithm" => :LD_SLSQP))
]

results = DataFrame(Problem = String[], Solver = String[], Time_sec = Float64[], Iterations = Int[], Status = String[], Objective = Float64[])

println("Iniciando Benchmark dos Solvers...")

for (p_name, model_template) in get_test_models()
    for (s_name, solver) in solvers
        println("Resolvendo $p_name com $s_name...")
        
        m = copy(model_template)
        set_optimizer(m, solver)
        
        start_time = time()
        optimize!(m)
        elapsed_time = time() - start_time
        
        status = string(termination_status(m))
        obj_val = has_values(m) ? objective_value(m) : NaN
        
        iters = -1
        try
            iters = barrier_iterations(m)
        catch
        end
        
        push!(results, (p_name, s_name, round(elapsed_time, digits=4), iters, status, round(obj_val, digits=4)))
    end
end

println("Salvo em benchmark_results.csv")
CSV.write("benchmark_results.csv", results)

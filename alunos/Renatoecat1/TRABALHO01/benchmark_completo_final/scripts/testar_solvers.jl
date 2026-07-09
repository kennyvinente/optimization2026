using JuMP
using Ipopt
using MadNLP
using CSV
using DataFrames

solvers = Dict(
    "Ipopt" => Ipopt.Optimizer,
    "MadNLP" => MadNLP.Optimizer
)

resultados = DataFrame(
    solver = String[],
    status = String[],
    objetivo = Float64[],
    tempo_s = Float64[]
)

for (nome, solver) in solvers
    t0 = time()

    model = Model(solver)
    set_silent(model)

    @variable(model, x >= 0)
    @variable(model, y >= 0)

    @NLobjective(model, Min, (x - 1)^2 + (y - 2)^2)
    @constraint(model, x + y >= 1)

    optimize!(model)

    push!(resultados, (
        nome,
        string(termination_status(model)),
        objective_value(model),
        time() - t0
    ))
end

CSV.write("resultados/teste_solvers.csv", resultados)

println(resultados)
println("Arquivo gerado: resultados/teste_solvers.csv")
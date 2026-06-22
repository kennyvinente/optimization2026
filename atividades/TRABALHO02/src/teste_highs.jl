using JuMP
using HiGHS

model = Model(HiGHS.Optimizer)

@variable(model, x >= 0)
@variable(model, y >= 0)

@objective(model, Max, 3x + 2y)

@constraint(model, x + y <= 10)
@constraint(model, 2x + y <= 15)

optimize!(model)

println("Status: ", termination_status(model))
println("Objetivo: ", objective_value(model))
println("x = ", value(x))
println("y = ", value(y))
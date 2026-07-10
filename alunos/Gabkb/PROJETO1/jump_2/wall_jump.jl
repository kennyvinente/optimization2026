using JuMP
using Ipopt

model = Model(Ipopt.Optimizer)

@variable(model, objvar)
@variable(model, x[2:6])

# Initial values
set_start_value(objvar, 1.0)
for i in 2:6
    set_start_value(x[i], 1.0)
end

# Equações
@NLconstraint(model, e1, objvar * x[2] == 1)

@NLconstraint(model, e2, x[3] / objvar / x[4] == 4.8)

@NLconstraint(model, e3, x[5] / x[2] / x[6] == 0.98)

@NLconstraint(model, e4, x[6] * x[4] == 1)

@constraint(model, e5, objvar - x[2] + 1e-7*x[3] - 1e-5*x[5] == 0)

@constraint(model, e6, 2*objvar - 2*x[2] + 1e-7*x[3] - 0.01*x[4] - 1e-5*x[5] + 0.01*x[6] == 0)

@objective(model, Min, objvar)

optimize!(model)

println("Status: ", termination_status(model))
println("Objective: ", objective_value(model))
println("objvar = ", value(objvar))
for i in 2:6
    println("x", i, " = ", value(x[i]))
end

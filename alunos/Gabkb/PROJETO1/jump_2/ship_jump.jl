using JuMP
using Ipopt

function build_model(; optimizer = Ipopt.Optimizer)
    model = Model(optimizer)

    @variable(model, x[1:10])
    @variable(model, objvar)

    # Bounds
    set_lower_bound(x[4], 1.05)
    set_lower_bound(x[5], 1.05)
    set_lower_bound(x[6], 1.05)

    # Initial values
    set_start_value(x[1], 934.032)
    set_start_value(x[2], 934.032)
    set_start_value(x[3], 1011.868)
    set_start_value(x[4], 1.2)
    set_start_value(x[5], 1.2)
    set_start_value(x[6], 1.3)
    set_start_value(x[7], 45.8)
    set_start_value(x[8], 43.2)
    set_start_value(x[9], 30.5)
    set_start_value(x[10], 76.3939536510076)

    # Objective
    @objective(model, Min, objvar)

    # Constraints
    @NLconstraint(model, -0.5*x[9]*x[4]*(0.8*x[7] + 0.333333333333333*x[8]) + x[1] == 0)
    @NLconstraint(model, -0.5*x[9]*x[5]*(0.8*x[7] + 0.333333333333333*x[8]) + x[2] == 0)
    @NLconstraint(model, -0.5*x[9]*x[6]*(0.8*x[7] + 0.333333333333333*x[8]) + x[3] == 0)
    @NLconstraint(model, (x[10] - x[7])^2 - (x[8]^2 - x[9]^2) == 0)

    @constraint(model, x[1] - 8.4652734375*x[10] >= 0)
    @constraint(model, x[2] - 9.65006510416667*x[10] >= 0)
    @constraint(model, x[3] - 8.8716796875*x[10] >= 0)

    @NLconstraint(model, 0.5*x[1]*x[9] - 2.2*(8.4652734375*x[10])^1.33333333333333 >= 0)
    @NLconstraint(model, 0.5*x[2]*x[9] - 2.2*(9.65006510416667*x[10])^1.33333333333333 >= 0)
    @NLconstraint(model, 0.5*x[3]*x[9] - 2.2*(8.8716796875*x[10])^1.33333333333333 >= 0)

    @constraint(model, x[4] - 0.0111771747883801*x[7] >= 0.2)
    @constraint(model, x[5] - 0.0137655360411427*x[7] >= 0.2)
    @constraint(model, x[6] - 0.0155663872253648*x[7] >= 0.2)
    @constraint(model, x[4] - 0.0111771747883801*x[8] >= 0.2)
    @constraint(model, x[5] - 0.0137655360411427*x[8] >= 0.2)
    @constraint(model, x[6] - 0.0155663872253648*x[8] >= 0.2)

    @NLconstraint(model, -((0.0039*x[7] + 0.0039*x[8])*(495*x[4] + 385*x[5] + 315*x[6]) / x[10]) + objvar == 0)

    return model
end

model = build_model()
optimize!(model)

println("termination_status = ", termination_status(model))
println("primal_status      = ", primal_status(model))
println("objective_value    = ", objective_value(model))

for i in 1:10
    println("x", i, " = ", value(x[i]))
end
println("objvar = ", value(objvar))

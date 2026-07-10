using JuMP

function build_ex5_2_5_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:32] >= 0)
    @variable(model, objvar)

    upper = Dict(
        1 => 1.0, 2 => 1.0, 3 => 1.0, 4 => 1.0, 5 => 1.0, 6 => 1.0,
        7 => 1.0, 8 => 1.0, 9 => 1.0, 10 => 1.0, 11 => 1.0, 12 => 1.0,
        13 => 100.0, 14 => 200.0, 15 => 100.0, 16 => 100.0, 17 => 100.0,
        18 => 100.0, 19 => 200.0, 20 => 100.0, 21 => 100.0, 22 => 100.0,
        23 => 100.0, 24 => 200.0, 25 => 100.0, 26 => 100.0, 27 => 100.0,
        28 => 100.0, 29 => 200.0, 30 => 100.0, 31 => 100.0, 32 => 100.0,
    )
    for (i, ub) in upper
        set_upper_bound(x[i], ub)
    end

    price = [18.0, 15.0, 19.0, 16.0, 14.0]
    slack_cost = [8.0, 5.0, 9.0, 6.0, 4.0]
    capacity = [100.0, 200.0, 100.0, 100.0, 100.0]
    flow_idx = [18 19 20 21 22;
                23 24 25 26 27;
                28 29 30 31 32]

    @constraint(model, e1,
        -sum((price[k] - 6.0*x[s] - 16.0*x[s+3] - 15.0*x[s+6] - 12.0*x[s+9]) *
             x[flow_idx[s, k]] for s in 1:3, k in 1:5) -
        sum(slack_cost[k] * x[12 + k] for k in 1:5) - objvar == 0.0
    )

    @constraint(model, e2,
        sum(x[s+6] * x[flow_idx[s, k]] for s in 1:3, k in 1:5) <= 50.0
    )
    @constraint(model, e_capacity[k in 1:5],
        x[12 + k] + sum(x[flow_idx[s, k]] for s in 1:3) <= capacity[k]
    )

    @constraint(model, e8,
        sum((3.0*x[s] + x[s+3] + x[s+6] + 1.5*x[s+9] - 2.5) * x[flow_idx[s,1]] for s in 1:3) - 0.5*x[13] <= 0.0
    )
    @constraint(model, e9,
        sum((x[s] + 3.0*x[s+3] + 2.5*x[s+6] + 2.5*x[s+9] - 2.0) * x[flow_idx[s,1]] for s in 1:3) + 0.5*x[13] <= 0.0
    )
    @constraint(model, e10,
        sum((3.0*x[s] + x[s+3] + x[s+6] + 1.5*x[s+9] - 1.5) * x[flow_idx[s,2]] for s in 1:3) + 0.5*x[14] <= 0.0
    )
    @constraint(model, e11,
        sum((x[s] + 3.0*x[s+3] + 2.5*x[s+6] + 2.5*x[s+9] - 2.5) * x[flow_idx[s,2]] for s in 1:3) <= 0.0
    )
    @constraint(model, e12,
        sum((3.0*x[s] + x[s+3] + x[s+6] + 1.5*x[s+9] - 2.0) * x[flow_idx[s,3]] for s in 1:3) <= 0.0
    )
    @constraint(model, e13,
        sum((x[s] + 3.0*x[s+3] + 2.5*x[s+6] + 2.5*x[s+9] - 2.6) * x[flow_idx[s,3]] for s in 1:3) - 0.1*x[15] <= 0.0
    )
    @constraint(model, e14,
        sum((3.0*x[s] + x[s+3] + x[s+6] + 1.5*x[s+9] - 2.0) * x[flow_idx[s,4]] for s in 1:3) <= 0.0
    )
    @constraint(model, e15,
        sum((x[s] + 3.0*x[s+3] + 2.5*x[s+6] + 2.5*x[s+9] - 2.0) * x[flow_idx[s,4]] for s in 1:3) + 0.5*x[16] <= 0.0
    )
    @constraint(model, e16,
        sum((3.0*x[s] + x[s+3] + x[s+6] + 1.5*x[s+9] - 2.0) * x[flow_idx[s,5]] for s in 1:3) <= 0.0
    )
    @constraint(model, e17,
        sum((x[s] + 3.0*x[s+3] + 2.5*x[s+6] + 2.5*x[s+9] - 2.0) * x[flow_idx[s,5]] for s in 1:3) + 0.5*x[17] <= 0.0
    )

    @constraint(model, e_mix[s in 1:3], x[s] + x[s+3] + x[s+6] + x[s+9] == 1.0)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_ex5_2_5_model()
for i in 1:32
    @eval $(Symbol(:x, i)) = x[$i]
end

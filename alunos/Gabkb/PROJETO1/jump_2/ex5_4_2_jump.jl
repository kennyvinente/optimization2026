using JuMP

function build_ex5_4_2_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:8])
    @variable(model, objvar)

    lows = [100.0, 1000.0, 1000.0, 10.0, 10.0, 10.0, 10.0, 10.0]
    ups  = [10000.0, 10000.0, 10000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0]
    for i in 1:8
        set_lower_bound(x[i], lows[i])
        set_upper_bound(x[i], ups[i])
    end

    @constraint(model, e1, -x[1] - x[2] - x[3] + objvar == 0.0)
    @constraint(model, e2, x[4] + x[6] <= 400.0)
    @constraint(model, e3, -x[4] + x[5] + x[7] <= 300.0)
    @constraint(model, e4, -x[5] + x[8] <= 100.0)
    @constraint(model, e5, x[1] - x[1]*x[6] + 833.333333333333*x[4] <= 83333.3333333333)
    @constraint(model, e6, x[2]*x[4] - x[2]*x[7] - 1250.0*x[4] + 1250.0*x[5] <= 0.0)
    @constraint(model, e7, x[3]*x[5] - x[3]*x[8] - 2500.0*x[5] <= -1250000.0)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_ex5_4_2_model()
for i in 1:8
    @eval $(Symbol(:x, i)) = x[$i]
end

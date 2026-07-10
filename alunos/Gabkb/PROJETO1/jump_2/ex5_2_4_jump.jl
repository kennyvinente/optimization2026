using JuMP

function build_ex5_2_4_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:7] >= 0)
    @variable(model, objvar)

    set_upper_bound(x[1], 1.0)
    set_upper_bound(x[2], 1.0)
    set_upper_bound(x[3], 1.0)
    set_upper_bound(x[4], 100.0)
    set_upper_bound(x[5], 200.0)
    set_upper_bound(x[6], 100.0)
    set_upper_bound(x[7], 200.0)

    @constraint(model, e1,
        -((9.0 - 6.0*x[1] - 16.0*x[2] - 15.0*x[3]) * x[4] +
          (15.0 - 6.0*x[1] - 16.0*x[2] - 15.0*x[3]) * x[5]) +
        x[6] - 5.0*x[7] - objvar == 0.0
    )
    @constraint(model, e2, x[3]*x[4] + x[3]*x[5] <= 50.0)
    @constraint(model, e3, x[4] + x[6] <= 100.0)
    @constraint(model, e4, x[5] + x[7] <= 200.0)
    @constraint(model, e5, (3.0*x[1] + x[2] + x[3] - 2.5)*x[4] - 0.5*x[6] <= 0.0)
    @constraint(model, e6, (3.0*x[1] + x[2] + x[3] - 1.5)*x[5] + 0.5*x[7] <= 0.0)
    @constraint(model, e7, x[1] + x[2] + x[3] == 1.0)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_ex5_2_4_model()
for i in 1:7
    @eval $(Symbol(:x, i)) = x[$i]
end

using JuMP

function build_ex5_4_3_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:16])
    @variable(model, objvar)

    bounds = Dict(
        1 => (10.0, 350.0), 2 => (10.0, 350.0), 3 => (10.0, 200.0), 4 => (10.0, 200.0),
        5 => (0.0, 10.0), 6 => (0.0, 10.0), 7 => (0.0, 10.0), 8 => (0.0, 10.0),
        9 => (0.0, 10.0), 10 => (0.0, 10.0), 11 => (0.0, 10.0), 12 => (0.0, 10.0),
        13 => (150.0, 310.0), 14 => (150.0, 310.0), 15 => (150.0, 310.0), 16 => (150.0, 310.0),
    )
    for i in 1:16
        set_lower_bound(x[i], bounds[i][1])
        set_upper_bound(x[i], bounds[i][2])
    end

    @constraint(model, e1, x[5] + x[9] == 10.0)
    @constraint(model, e2, x[5] - x[6] + x[11] == 0.0)
    @constraint(model, e3, x[7] + x[9] - x[10] == 0.0)
    @constraint(model, e4, -x[6] + x[7] + x[8] == 0.0)
    @constraint(model, e5, -x[10] + x[11] + x[12] == 0.0)
    @constraint(model, e6, x[16]*x[11] - x[13]*x[6] + 150.0*x[5] == 0.0)
    @constraint(model, e7, x[15]*x[7] - x[14]*x[10] + 150.0*x[9] == 0.0)
    @constraint(model, e8, x[6]*x[15] - x[6]*x[13] == 1000.0)
    @constraint(model, e9, x[10]*x[16] - x[10]*x[14] == 600.0)
    @constraint(model, e10, x[1] + x[15] == 500.0)
    @constraint(model, e11, x[2] + x[13] == 250.0)
    @constraint(model, e12, x[3] + x[16] == 350.0)
    @constraint(model, e13, x[4] + x[14] == 200.0)
    @constraint(model, e14,
        -(1300.0*(1000.0/(0.0333333333333333*x[1]*x[2] + 0.166666666666667*x[1] + 0.166666666666667*x[2]))^0.6 +
          1300.0*(600.0/(0.0333333333333333*x[3]*x[4] + 0.166666666666667*x[3] + 0.166666666666667*x[4]))^0.6) + objvar == 0.0
    )

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_ex5_4_3_model()
for i in 1:16
    @eval $(Symbol(:x, i)) = x[$i]
end

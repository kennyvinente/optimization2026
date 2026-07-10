using JuMP

function build_ex5_4_4_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:27])
    @variable(model, objvar)

    for i in 1:6
        set_lower_bound(x[i], 10.0)
        set_upper_bound(x[i], 110.0)
    end
    for i in 7:21
        set_lower_bound(x[i], 0.0)
        set_upper_bound(x[i], 45.0)
    end
    for i in 22:27
        set_lower_bound(x[i], 100.0)
        set_upper_bound(x[i], 200.0)
    end

    @constraint(model, e1, x[7] + x[12] + x[17] == 45.0)
    @constraint(model, e2, x[7] - x[8] + x[14] + x[20] == 0.0)
    @constraint(model, e3, x[9] + x[12] - x[13] + x[19] == 0.0)
    @constraint(model, e4, x[10] + x[15] + x[17] - x[18] == 0.0)
    @constraint(model, e5, -x[8] + x[9] + x[10] + x[11] == 0.0)
    @constraint(model, e6, -x[13] + x[14] + x[15] + x[16] == 0.0)
    @constraint(model, e7, -x[18] + x[19] + x[20] + x[21] == 0.0)
    @constraint(model, e8, x[25]*x[14] + x[27]*x[20] - x[22]*x[8] + 100.0*x[7] == 0.0)
    @constraint(model, e9, x[23]*x[9] + x[27]*x[19] - x[24]*x[13] + 100.0*x[12] == 0.0)
    @constraint(model, e10, x[23]*x[10] + x[25]*x[15] - x[26]*x[18] + 100.0*x[17] == 0.0)
    @constraint(model, e11, x[8]*x[23] - x[8]*x[22] == 2000.0)
    @constraint(model, e12, x[13]*x[25] - x[13]*x[24] == 1000.0)
    @constraint(model, e13, x[18]*x[27] - x[18]*x[26] == 1500.0)
    @constraint(model, e14, x[1] + x[23] == 210.0)
    @constraint(model, e15, x[2] + x[22] == 130.0)
    @constraint(model, e16, x[3] + x[25] == 210.0)
    @constraint(model, e17, x[4] + x[24] == 160.0)
    @constraint(model, e18, x[5] + x[27] == 210.0)
    @constraint(model, e19, x[6] + x[26] == 180.0)
    @constraint(model, e20,
        -(1300.0*(2000.0/(0.333333333333333*x[1]*x[2] + 0.166666666666667*x[1] + 0.166666666666667*x[2]))^0.6 +
          1300.0*(1000.0/(0.666666666666667*x[3]*x[4] + 0.166666666666667*x[3] + 0.166666666666667*x[4]))^0.6 +
          1300.0*(1500.0/(0.666666666666667*x[5]*x[6] + 0.166666666666667*x[5] + 0.166666666666667*x[6]))^0.6) + objvar == 0.0
    )

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_ex5_4_4_model()
for i in 1:27
    @eval $(Symbol(:x, i)) = x[$i]
end

using JuMP

function build_ex5_3_2_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:22] >= 0)
    @variable(model, objvar)

    for i in 1:18
        set_upper_bound(x[i], 300.0)
    end
    for i in 19:22
        set_upper_bound(x[i], 1.0)
    end

    @constraint(model, e1, x[1] + x[2] + x[3] + x[4] == 300.0)
    @constraint(model, e2, x[5] - x[6] - x[7] == 0.0)
    @constraint(model, e3, x[8] - x[9] - x[10] - x[11] == 0.0)
    @constraint(model, e4, x[12] - x[13] - x[14] - x[15] == 0.0)
    @constraint(model, e5, x[16] - x[17] - x[18] == 0.0)
    @constraint(model, e6, x[13]*x[21] + 0.333*x[1] - x[5] == 0.0)
    @constraint(model, e7, x[13]*x[22] - x[8]*x[20] + 0.333*x[1] == 0.0)
    @constraint(model, e8, -x[8]*x[19] + 0.333*x[1] == 0.0)
    @constraint(model, e9, -x[12]*x[21] - 0.333*x[2] == 0.0)
    @constraint(model, e10, x[9]*x[20] - x[12]*x[22] + 0.333*x[2] == 0.0)
    @constraint(model, e11, x[9]*x[19] + 0.333*x[2] - x[16] == 0.0)
    @constraint(model, e12, x[14]*x[21] + 0.333*x[3] + x[6] == 30.0)
    @constraint(model, e13, x[10]*x[20] + x[14]*x[22] + 0.333*x[3] == 50.0)
    @constraint(model, e14, x[10]*x[19] + 0.333*x[3] + x[17] == 30.0)
    @constraint(model, e15, x[19] + x[20] == 1.0)
    @constraint(model, e16, x[21] + x[22] == 1.0)
    @constraint(model, e17, -0.00432*x[1] - 0.01517*x[2] - 0.01517*x[9] - 0.00432*x[13] + objvar == 0.9979)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_ex5_3_2_model()
for i in 1:22
    @eval $(Symbol(:x, i)) = x[$i]
end

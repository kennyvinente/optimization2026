using JuMP

function build_harker_model(; optimizer = nothing, set_starts::Bool = true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:20] >= 0)
    @variable(model, objvar)

    if set_starts
        for i in 15:20
            set_start_value(x[i], 25.0)
        end
    end

    @constraint(model, e1,  x[15] + x[16] + x[17] - x[18] - x[19] - x[20] == 0)
    @constraint(model, e2, -x[1] - x[2] + x[5] + x[8] - x[15] + x[18] == 0)
    @constraint(model, e3, -x[3] + x[11] - x[16] + x[19] == 0)
    @constraint(model, e4, -x[4] + x[12] - x[17] + x[20] == 0)
    @constraint(model, e5,  x[1] - x[5] - x[6] - x[7] + x[9] + x[13] == 0)
    @constraint(model, e6,  x[2] + x[6] - x[8] - x[9] - x[10] + x[14] == 0)
    @constraint(model, e7,  x[3] + x[4] + x[7] + x[10] - x[11] - x[12] - x[13] - x[14] == 0)

    @expression(model, benefit,
        19*x[15] - 0.1*x[15]^2 - 0.5*x[18]^2 - x[18] - 0.005*x[16]^2 + 27*x[16] -
        0.4*x[19]^2 - 2*x[19] - 0.15*x[17]^2 + 30*x[17] - 0.3*x[20]^2 - 1.5*x[20]
    )
    @expression(model, cost,
        (1/6)*x[1]^3 + x[1] + (1/15)*x[2]^3 + 2*x[2] + 0.1*x[3]^3 + 3*x[3] +
        (2/15)*x[4]^3 + x[4] + 0.1*x[5]^3 + 2*x[5] + (1/30)*x[6]^3 + x[6] +
        (1/30)*x[7]^3 + x[7] + (1/6)*x[8]^3 + 3*x[8] + (1/15)*x[9]^3 + 2*x[9] +
        (1/3)*x[10]^3 + x[10] + (1/12)*x[11]^3 + 2*x[11] + (1/15)*x[12]^3 + 2*x[12] +
        0.3*x[13]^3 + x[13] + (4/15)*x[14]^3 + 3*x[14]
    )
    @constraint(model, e8, -(benefit - cost) - objvar == 0)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_harker_model()
for i in 1:20
    @eval $(Symbol(:x, i)) = x[$i]
end

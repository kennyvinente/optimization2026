# ex3_1_4_jump.jl
# Modelo JuMP convertido de GAMS Convert

using JuMP

function build_ex3_1_4_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, 0.0 <= x1 <= 2.0)
    @variable(model, x2 >= 0.0)
    @variable(model, 0.0 <= x3 <= 3.0)
    @variable(model, objvar)

    @constraint(model, e1, 2.0 * x1 - x2 + x3 + objvar == 0.0)

    @constraint(model, e2,
        x1 * (4.0 * x1 - 2.0 * x2 + 2.0 * x3) +
        x2 * (2.0 * x2 - 2.0 * x1 - x3) +
        x3 * (2.0 * x1 - x2 + 2.0 * x3) -
        20.0 * x1 + 9.0 * x2 - 13.0 * x3 >= -24.0
    )

    @constraint(model, e3, x1 + x2 + x3 <= 4.0)
    @constraint(model, e4, 3.0 * x2 + x3 <= 6.0)

    @objective(model, Min, objvar)

    if set_starts
        set_start_value(x1, 0.5)
        set_start_value(x3, 3.0)
    end

    return model, x1, x2, x3, objvar
end

model, x1, x2, x3, objvar = build_ex3_1_4_model()

# ex3_1_3_jump.jl
# Modelo JuMP convertido de GAMS Convert

using JuMP

function build_ex3_1_3_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x1 >= 0.0)
    @variable(model, x2 >= 0.0)
    @variable(model, 1.0 <= x3 <= 5.0)
    @variable(model, 0.0 <= x4 <= 6.0)
    @variable(model, 1.0 <= x5 <= 5.0)
    @variable(model, 0.0 <= x6 <= 10.0)
    @variable(model, objvar)

    @constraint(model, e1,
        25.0 * (x1 - 2.0)^2 + (x2 - 2.0)^2 + (x3 - 1.0)^2 +
        (x4 - 4.0)^2 + (x5 - 1.0)^2 + (x6 - 4.0)^2 + objvar == 0.0
    )

    @constraint(model, e2, (x3 - 3.0)^2 + x4 >= 4.0)
    @constraint(model, e3, (x5 - 3.0)^2 + x6 >= 4.0)
    @constraint(model, e4, x1 - 3.0 * x2 <= 2.0)
    @constraint(model, e5, -x1 + x2 <= 2.0)
    @constraint(model, e6, x1 + x2 <= 6.0)
    @constraint(model, e7, x1 + x2 >= 2.0)

    @objective(model, Min, objvar)

    if set_starts
        set_start_value(x1, 5.0)
        set_start_value(x2, 1.0)
        set_start_value(x3, 5.0)
        set_start_value(x5, 5.0)
        set_start_value(x6, 10.0)
    end

    return model, x1, x2, x3, x4, x5, x6, objvar
end

model, x1, x2, x3, x4, x5, x6, objvar = build_ex3_1_3_model()

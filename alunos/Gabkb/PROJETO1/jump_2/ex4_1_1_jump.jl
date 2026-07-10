# ex4_1_1_jump.jl
# Convertido de GAMS Convert para JuMP

using JuMP

function build_ex4_1_1_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, -2.0 <= x1 <= 11.0)
    @variable(model, objvar)

    if set_starts
        set_start_value(x1, 10.0)
    end

    poly = x1^6 - 2.08*x1^5 + 0.4875*x1^4 + 7.1*x1^3 - 3.95*x1^2 - x1

    @constraint(model, e1, -poly + objvar == 0.1)
    @objective(model, Min, objvar)

    return model, x1, objvar
end

model, x1, objvar = build_ex4_1_1_model()

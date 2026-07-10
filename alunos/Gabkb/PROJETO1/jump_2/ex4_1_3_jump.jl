# ex_4_1_3_jump.jl
# Convertido de GAMS Convert para JuMP

using JuMP

function build_ex_4_1_3_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, 0.0 <= x1 <= 10.0)
    @variable(model, objvar)

    if set_starts
        set_start_value(x1, 6.325)
    end

    poly = 8.9248e-5*x1 - 0.0218343*x1^2 + 0.998266*x1^3 - 1.6995*x1^4 + 0.2*x1^5

    @constraint(model, e1, -poly + objvar == 0.0)
    @objective(model, Min, objvar)

    return model, x1, objvar
end

model, x1, objvar = build_ex_4_1_3_model()

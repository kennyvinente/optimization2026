# ex_1_3 convertido de GAMS scalar para JuMP
# NLP minimizando objvar

using JuMP

function build_ex_1_3_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, 5.49e-6 <= x1 <= 4.553)
    @variable(model, 0.0021961 <= x2 <= 18.21)
    @variable(model, x3)
    @variable(model, objvar)

    if set_starts
        set_start_value(x1, 1.0)
        set_start_value(x2, 1.0)
        set_start_value(x3, 1.0)
        set_start_value(objvar, 1.0)
    end

    @objective(model, Min, objvar)

    @constraint(model, e1, -x3 + objvar == 0)
    @constraint(model, e2, 10000*x1*x2 - x3 <= 1)
    @constraint(model, e3, -10000*x1*x2 - x3 <= -1)
    @constraint(model, e4, exp(-x1) + exp(-x2) - x3 <= 1.001)
    @constraint(model, e5, -exp(-x1) - exp(-x2) - x3 <= -1.001)

    return model
end

model = build_ex_1_3_model()

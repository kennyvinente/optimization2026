# ex_1_9 convertido de GAMS scalar para JuMP
# NLP minimizando objvar

using JuMP

function build_ex_1_9_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, 100 <= x1 <= 1000)
    @variable(model, x2)
    @variable(model, objvar)

    if set_starts
        set_start_value(x1, 500.0)
        set_start_value(x2, 1.0)
        set_start_value(objvar, 1.0)
    end

    @objective(model, Min, objvar)

    @constraint(model, e1, -x2 + objvar == 0)
    @constraint(model, e2,
        4510067.11409396*x1*exp(-7548.11926028431/x1) +
        0.00335570469798658*x1 -
        2020510067.11409*exp(-7548.11926028431/x1) - x2 <= 1
    )
    @constraint(model, e3,
        -4510067.11409396*x1*exp(-7548.11926028431/x1) -
        0.00335570469798658*x1 +
        2020510067.11409*exp(-7548.11926028431/x1) - x2 <= -1
    )

    return model
end

model = build_ex_1_9_model()

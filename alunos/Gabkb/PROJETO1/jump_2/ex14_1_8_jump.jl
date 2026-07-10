# ex_1_8 convertido de GAMS scalar para JuMP
# NLP minimizando objvar

using JuMP

function build_ex_1_8_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, 0 <= x1 <= 1)
    @variable(model, 0 <= x2 <= 1)
    @variable(model, x3)
    @variable(model, objvar)

    if set_starts
        set_start_value(x1, 0.1)
        set_start_value(x2, 0.1)
        set_start_value(x3, 1.0)
        set_start_value(objvar, 1.0)
    end

    @objective(model, Min, objvar)

    @constraint(model, e1, -x3 + objvar == 0)
    @constraint(model, e2, (0.0476666666666666 - 0.0649999999999999*x1)*exp(10*x1/(1 + 0.01*x1)) - x1 - x3 <= 0)
    @constraint(model, e3, x1 - (0.0476666666666666 - 0.0649999999999999*x1)*exp(10*x1/(1 + 0.01*x1)) - x3 <= 0)
    @constraint(model, e4, (0.143 - 0.13*x1 - 0.195*x2)*exp(10*x2/(1 + 0.01*x2)) + x1 - 3*x2 - x3 <= 0)
    @constraint(model, e5, -(0.143 - 0.13*x1 - 0.195*x2)*exp(10*x2/(1 + 0.01*x2)) - x1 + 3*x2 - x3 <= 0)

    return model
end

model = build_ex_1_8_model()

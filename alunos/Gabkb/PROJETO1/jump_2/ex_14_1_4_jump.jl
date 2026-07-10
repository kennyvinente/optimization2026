# ex_14_1_4 convertido de GAMS scalar para JuMP
# NLP minimizando objvar

using JuMP

function build_ex_14_1_4_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, 0.25 <= x1 <= 1)
    @variable(model, 1.5 <= x2 <= 6.28)
    @variable(model, x3)
    @variable(model, objvar)

    if set_starts
        set_start_value(x1, 0.5)
        set_start_value(x2, 3.0)
        set_start_value(x3, 1.0)
        set_start_value(objvar, 1.0)
    end

    @objective(model, Min, objvar)

    @constraint(model, e1, 0.5*sin(x1*x2) - 0.5*x1 - 0.0795774703703634*x2 - x3 <= 0)
    @constraint(model, e2, 0.920422529629637*exp(2*x1) - 5.4365636*x1 + 0.865255957591193*x2 - x3 <= 2.5019678106022)
    @constraint(model, e3, 0.5*x1 - 0.5*sin(x1*x2) + 0.0795774703703634*x2 - x3 <= 0)
    @constraint(model, e4, -x3 + objvar == 0)
    @constraint(model, e5, 5.4365636*x1 - 0.920422529629637*exp(2*x1) - 0.865255957591193*x2 - x3 <= -2.5019678106022)

    return model
end

model = build_ex_14_1_4_model()

# ex_14_1_5 convertido de GAMS scalar para JuMP
# NLP minimizando objvar

using JuMP

function build_ex_14_1_5_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, -2 <= x1 <= 2)
    @variable(model, -2 <= x2 <= 2)
    @variable(model, -2 <= x3 <= 2)
    @variable(model, -2 <= x4 <= 2)
    @variable(model, -2 <= x5 <= 2)
    @variable(model, x6)
    @variable(model, objvar)

    if set_starts
        for v in (x1, x2, x3, x4, x5)
            set_start_value(v, 1.0)
        end
        set_start_value(x6, 1.0)
        set_start_value(objvar, 1.0)
    end

    @objective(model, Min, objvar)

    @constraint(model, e1, -x6 + objvar == 0)
    @constraint(model, e2, 2*x1 + x2 + x3 + x4 + x5 == 6)
    @constraint(model, e3, x1 + 2*x2 + x3 + x4 + x5 == 6)
    @constraint(model, e4, x1 + x2 + 2*x3 + x4 + x5 == 6)
    @constraint(model, e5, x1 + x2 + x3 + 2*x4 + x5 == 6)
    @constraint(model, e6, x1*x2*x3*x4*x5 - x6 <= 1)
    @constraint(model, e7, -x1*x2*x3*x4*x5 - x6 <= -1)

    return model
end

model = build_ex_14_1_5_model()

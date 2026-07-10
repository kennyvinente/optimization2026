# ex_14_6 convertido de GAMS scalar para JuMP
# NLP minimizando objvar

using JuMP

function build_ex_14_6_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, -1 <= x1 <= 1)
    @variable(model, -1 <= x2 <= 1)
    @variable(model, -1 <= x3 <= 1)
    @variable(model, -1 <= x4 <= 1)
    @variable(model, -1 <= x5 <= 1)
    @variable(model, -1 <= x6 <= 1)
    @variable(model, -1 <= x7 <= 1)
    @variable(model, -1 <= x8 <= 1)
    @variable(model, x9)
    @variable(model, objvar)

    if set_starts
        for v in (x1, x2, x3, x4, x5, x6, x7, x8)
            set_start_value(v, 0.0)
        end
        set_start_value(x9, 1.0)
        set_start_value(objvar, 1.0)
    end

    @objective(model, Min, objvar)

    @constraint(model, e1, -x9 + objvar == 0)
    @constraint(model, e2, 0.004731*x1*x3 - 0.1238*x1 - 0.3578*x2*x3 - 0.001637*x2 - 0.9338*x4 + x7 - x9 <= 0.3571)
    @constraint(model, e3, 0.1238*x1 - 0.004731*x1*x3 + 0.3578*x2*x3 + 0.001637*x2 + 0.9338*x4 - x7 - x9 <= -0.3571)
    @constraint(model, e4, 0.2238*x1*x3 + 0.2638*x1 + 0.7623*x2*x3 - 0.07745*x2 - 0.6734*x4 - x7 - x9 <= 0.6022)
    @constraint(model, e5, -0.2238*x1*x3 - 0.2638*x1 - 0.7623*x2*x3 + 0.07745*x2 + 0.6734*x4 + x7 - x9 <= -0.6022)
    @constraint(model, e6, x6*x8 + 0.3578*x1 + 0.004731*x2 - x9 <= 0)
    @constraint(model, e7, -x6*x8 - 0.3578*x1 - 0.004731*x2 - x9 <= 0)
    @constraint(model, e8, -0.7623*x1 + 0.2238*x2 == -0.3461)
    @constraint(model, e9, x1^2 + x2^2 - x9 <= 1)
    @constraint(model, e10, -x1^2 - x2^2 - x9 <= -1)
    @constraint(model, e11, x3^2 + x4^2 - x9 <= 1)
    @constraint(model, e12, -x3^2 - x4^2 - x9 <= -1)
    @constraint(model, e13, x5^2 + x6^2 - x9 <= 1)
    @constraint(model, e14, -x5^2 - x6^2 - x9 <= -1)
    @constraint(model, e15, x7^2 + x8^2 - x9 <= 1)
    @constraint(model, e16, -x7^2 - x8^2 - x9 <= -1)

    return model
end

model = build_ex_14_6_model()

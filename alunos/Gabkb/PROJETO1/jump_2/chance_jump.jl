# Modelo JuMP convertido do GAMS Convert: chance
# Estrutura:
# - variáveis: objvar, x2, x3, x4, x5
# - x2..x5 positivas
# - 2 restrições de igualdade e 2 restrições >=
# - objetivo: Min objvar

using JuMP

function build_chance_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, objvar)
    @variable(model, x2 >= 0)
    @variable(model, x3 >= 0)
    @variable(model, x4 >= 0)
    @variable(model, x5 >= 0)

    # Chutes iniciais do GAMS
    set_start_value(objvar, 28.9426476516831)
    set_start_value(x2, 0.685244910300343)
    set_start_value(x3, 0.0126990526103601)
    set_start_value(x4, 0.302056037089293)
    set_start_value(x5, 0.0)

    @objective(model, Min, objvar)

    @constraint(
        model,
        e1,
        objvar - 24.55 * x2 - 26.75 * x3 - 39.0 * x4 - 40.5 * x5 == 0
    )

    @constraint(model, e2, x2 + x3 + x4 + x5 == 1)

    @constraint(
        model,
        e3,
        12.0 * x2
        - 1.645 * sqrt(0.28 * x2^2 + 0.19 * x3^2 + 20.5 * x4^2 + 0.62 * x5^2)
        + 11.9 * x3
        + 41.8 * x4
        + 52.1 * x5 >= 21.0
    )

    @constraint(
        model,
        e4,
        2.3 * x2 + 5.6 * x3 + 11.1 * x4 + 1.3 * x5 >= 5.0
    )

    return model, objvar, x2, x3, x4, x5
end

model, objvar, x2, x3, x4, x5 = build_chance_model()

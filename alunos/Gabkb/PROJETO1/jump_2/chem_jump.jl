# Modelo JuMP convertido a partir do GAMS Convert: chem
# NLP minimizando objvar

using JuMP

function build_chem_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:11])
    @variable(model, objvar)

    # Bounds do GAMS
    for i in 1:10
        set_lower_bound(x[i], 0.001)
    end
    set_lower_bound(x[11], 0.01)

    # Chutes iniciais simples e positivos para evitar log fora do domínio.
    for i in 1:10
        set_start_value(x[i], 0.1)
    end
    set_start_value(x[11], 1.0)
    set_start_value(objvar, 0.0)

    c = [
        6.05576803624071,
        17.1307680362407,
        34.0207680362407,
        5.88076803624071,
        24.6877680362407,
        14.9527680362407,
        24.0667680362407,
        10.6747680362407,
        26.6287680362407,
        22.1447680362407,
    ]

    @constraint(model, e1, x[1] + 2*x[2] + 2*x[3] + x[6] + x[10] == 2)
    @constraint(model, e2, x[4] + 2*x[5] + x[6] + x[7] == 1)
    @constraint(model, e3, x[3] + x[7] + x[8] + 2*x[9] + x[10] == 1)

    @constraint(
        model,
        e4,
        -sum(x[i] * (log(x[i] / x[11]) - c[i]) for i in 1:10) + objvar == 0
    )

    @constraint(model, e5, -sum(x[i] for i in 1:10) + x[11] == 0)

    @objective(model, Min, objvar)

    return model, x, objvar
end

model, x, objvar = build_chem_model()

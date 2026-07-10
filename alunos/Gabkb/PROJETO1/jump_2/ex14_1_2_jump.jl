# ex14_1_2 convertido de GAMS scalar para JuMP
# NLP minimizando objvar

using JuMP

function build_ex14_1_2_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, 0.0001 <= x1 <= 100)
    @variable(model, 0.0001 <= x2 <= 100)
    @variable(model, 0.0001 <= x3 <= 100)
    @variable(model, 0.0001 <= x4 <= 100)
    @variable(model, 0.0001 <= x5 <= 100)
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
    @constraint(model, e2, x1*x2 + x1 - 3*x5 == 0)

    @constraint(model, e3,
        2.8845e-6*x2^2 + 4.4975e-7*x2 + 2*x1*x2 + x1 +
        0.000545176668613029*x2*x3 + 3.40735417883143e-5*x2*x4 +
        x2*x3^2 - 10*x5 - x6 <= 0
    )

    @constraint(model, e4,
        -2.8845e-6*x2^2 - 4.4975e-7*x2 - 2*x1*x2 - x1 -
        0.000545176668613029*x2*x3 - 3.40735417883143e-5*x2*x4 -
        x2*x3^2 + 10*x5 - x6 <= 0
    )

    @constraint(model, e5,
        0.386*x3^2 + 0.000410621754172864*x3 +
        0.000545176668613029*x2*x3 + 2*x2*x3^2 - 8*x5 - x6 <= 0
    )

    @constraint(model, e6,
        -0.386*x3^2 - 0.000410621754172864*x3 -
        0.000545176668613029*x2*x3 - 2*x2*x3^2 + 8*x5 - x6 <= 0
    )

    @constraint(model, e7,
        2*x4^2 + 3.40735417883143e-5*x2*x4 - 40*x5 - x6 <= 0
    )

    @constraint(model, e8,
        -2*x4^2 - 3.40735417883143e-5*x2*x4 + 40*x5 - x6 <= 0
    )

    @constraint(model, e9,
        9.615e-7*x2^2 + 4.4975e-7*x2 + 0.193*x3^2 +
        0.000410621754172864*x3 + x4^2 + x1*x2 + x1 +
        0.000545176668613029*x2*x3 + 3.40735417883143e-5*x2*x4 +
        x2*x3^2 - x6 <= 1
    )

    @constraint(model, e10,
        -9.615e-7*x2^2 - 4.4975e-7*x2 - 0.193*x3^2 -
        0.000410621754172864*x3 - x4^2 - x1*x2 - x1 -
        0.000545176668613029*x2*x3 - 3.40735417883143e-5*x2*x4 -
        x2*x3^2 - x6 <= -1
    )

    return model
end

model = build_ex14_1_2_model()

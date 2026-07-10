using JuMP

"""
    build_alkyl_model(; optimizer=nothing, set_starts=true)

Modelo JuMP convertido do DAG do problema `alkyl`.

Variáveis originais preservadas conforme o DAG:
V0=x5, V1=x8, V2=x2, V3=x4, V4=x7, V5=x9, V6=x10,
V7=x11, V8=x12, V9=x13, V10=x14, V11=x15, V12=x3, V13=x6.
"""
function build_alkyl_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variables(model, begin
        0.0 <= x5  <= 5.0
        0.900000000000000022 <= x8  <= 0.949999999999999956
        0.0 <= x2  <= 2.0
        0.0 <= x4  <= 1.19999999999999996
        0.849999999999999978 <= x7  <= 0.930000000000000049
        3.0 <= x9  <= 12.0
        1.19999999999999996 <= x10 <= 4.0
        1.44999999999999996 <= x11 <= 1.62000000000000011
        0.989999999999999991 <= x12 <= 1.01010101010100994
        0.989999999999999991 <= x13 <= 1.01010101010100994
        0.900000000000000022 <= x14 <= 1.11111111111111005
        0.989999999999999991 <= x15 <= 1.01010101010100994
        0.0 <= x3  <= 1.60000000000000009
        0.0 <= x6  <= 2.0
    end)

    if set_starts
        set_start_value(x5,  2.5)
        set_start_value(x8,  0.925)
        set_start_value(x2,  1.0)
        set_start_value(x4,  0.6)
        set_start_value(x7,  0.89)
        set_start_value(x9,  7.5)
        set_start_value(x10, 2.6)
        set_start_value(x11, 1.535)
        set_start_value(x12, 1.0)
        set_start_value(x13, 1.0)
        set_start_value(x14, 1.0)
        set_start_value(x15, 1.0)
        set_start_value(x3,  0.8)
        set_start_value(x6,  1.0)
    end

    # Objetivo: node 14 do DAG, M 14 min
    @objective(model, Min,
        5.04 * x2 + x4 + 0.35 * x3 + 3.36 * x6 - 6.3 * x5 * x8
    )

    # Restrições nomeadas conforme o DAG:
    # C6 -> e2, C0 -> e3, C1 -> e4, C2 -> e5, C3 -> e6, C4 -> e7, C5 -> e8
    @constraints(model, begin
        e2, x5 - 0.819672131147541005 * x2 - 0.819672131147541005 * x6 == 0.0

        e3, 0.979999999999999982 * x4 - x7 * (x4 + 0.0100000000000000002 * x5 * x10) == 0.0

        e4, 10.0 * x3 + x6 - x2 * x9 == 0.0

        e5, x5 * x12 - x2 * (
            1.12000000000000011 +
            0.131670000000000009 * x9 -
            0.00670000000000000023 * x9^2
        ) == 0.0

        e6, -0.325000000000000011 * x7 -
            0.0109800000000000019 * x9 +
            x8 * x13 +
            0.000380000000000000021 * x9^2 == 0.574250000000000038

        e7, 22.1999999999999993 * x11 + x10 * x14 == 35.8200000000000003

        e8, -3.0 * x8 + x11 * x15 == -1.33000000000000007
    end)

    return model
end

# Modelo pronto para uso com `include("alkyl_jump.jl")`
model = build_alkyl_model()

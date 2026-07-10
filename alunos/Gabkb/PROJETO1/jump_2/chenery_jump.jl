# Modelo JuMP convertido a partir do GAMS Convert: chenery
# NLP minimizando objvar

using JuMP

function build_chenery_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:44])
    @variable(model, objvar)

    # Positive Variables do GAMS:
    for i in vcat(1:12, 17:36)
        set_lower_bound(x[i], 0.0)
    end

    # Bounds não padrão
    for i in 1:4
        set_upper_bound(x[i], 2000.0)
    end
    for i in 5:8
        set_upper_bound(x[i], 100.0)
    end
    for i in 9:12
        set_upper_bound(x[i], 2000.0)
    end
    for i in 13:16
        set_lower_bound(x[i], 0.1)
        set_upper_bound(x[i], 100.0)
    end
    for i in 17:24
        set_upper_bound(x[i], 1.0)
    end
    for i in 25:30
        set_upper_bound(x[i], 400.0)
    end
    for i in 31:36
        set_upper_bound(x[i], 4.0)
    end
    set_lower_bound(x[37], 0.25); set_upper_bound(x[37], 4.0)
    set_lower_bound(x[38], 0.25); set_upper_bound(x[38], 4.0)
    set_lower_bound(x[39], 0.01)
    # x[40] não aparece no GAMS como variável explícita útil; fica livre por compatibilidade de índice.
    for i in 41:44
        set_lower_bound(x[i], 0.001)
    end

    # Chutes iniciais do GAMS
    starts = Dict(
        1 => 200.0,
        2 => 200.0,
        3 => 200.0,
        4 => 200.0,
        5 => 1.08002386572984,
        6 => 1.25850763714561,
        7 => 2.47224270643972,
        8 => 2.08174548233022,
        9 => 250.0,
        10 => 250.0,
        11 => 250.0,
        12 => 250.0,
        13 => 3.0,
        14 => 3.0,
        15 => 3.0,
        16 => 3.0,
        17 => 0.283078383128534,
        18 => 0.383990781960791,
        19 => 0.309951359679435,
        20 => 0.580992426342466,
        21 => 0.22769870931466,
        22 => 0.249861958624235,
        23 => 0.617797527645794,
        24 => 0.428786587425074,
        31 => 1.0,
        32 => 1.0,
        33 => 1.0,
        34 => 1.0,
        35 => 1.1,
        36 => 1.0,
        37 => 3.5,
        38 => 3.5,
        39 => 0.3,
        41 => 0.171804999139287,
        42 => 0.349221638418406,
        43 => 15.7837604335036,
        44 => 0.00311417990544524,
    )
    for (i, v) in starts
        set_start_value(x[i], v)
    end
    set_start_value(objvar, -1000.0)

    # Equações
    @constraint(model, e1, -x[9] - x[10] - x[11] - x[12] - objvar == 0)

    @constraint(model, e2, x[1] - x[9] - x[25] + x[28] >= 0)
    @constraint(model, e3, -0.1*x[1] + x[2] - x[10] - x[26] + x[29] >= 0)
    @constraint(model, e4, -0.2*x[1] - 0.1*x[2] + x[3] - x[11] - x[27] + x[30] >= 0)
    @constraint(model, e5, -0.2*x[1] - 0.3*x[2] - 0.1*x[3] + x[4] - x[12] >= 0)

    @constraint(model, e6, x[31]*x[28] - x[34]*x[25] + x[32]*x[29] - x[35]*x[26] + x[33]*x[30] - x[36]*x[27] <= 0)

    @constraint(model, e7, -0.005*x[28] + x[31] == 1)
    @constraint(model, e8, -0.0157*x[29] + x[32] == 1)
    @constraint(model, e9, -0.00178*x[30] + x[33] == 1)
    @constraint(model, e10, 0.005*x[25] + x[34] == 1)
    @constraint(model, e11, 0.001*x[26] + x[35] == 1.1)
    @constraint(model, e12, 0.01*x[27] + x[36] == 1)

    @constraint(model, e13, -100*(x[39]*x[13])^(-0.674) + x[9] == 0)
    @constraint(model, e14, -230*(x[39]*x[14])^(-0.246) + x[10] == 0)
    @constraint(model, e15, -220*(x[39]*x[15])^(-0.587) + x[11] == 0)
    @constraint(model, e16, -450*(x[39]*x[16])^(-0.352) + x[12] == 0)

    @constraint(model, e17, x[17]*x[1] + x[18]*x[2] + x[19]*x[3] + x[20]*x[4] <= 750)
    @constraint(model, e18, x[21]*x[1] + x[22]*x[2] + x[23]*x[3] + x[24]*x[4] == 500)

    @constraint(model, e19, -x[5] + x[13] - 0.1*x[14] - 0.2*x[15] - 0.2*x[16] == 0)
    @constraint(model, e20, -x[6] + x[14] - 0.1*x[15] - 0.3*x[16] == 0)
    @constraint(model, e21, -x[7] + x[15] - 0.1*x[16] == 0)
    @constraint(model, e22, -x[8] + x[16] == 0)
    @constraint(model, e23, -x[37] + x[38] == 0)

    @constraint(model, e24, -(2.06748466257669*x[38])^(-0.89) + x[41] == 0)
    @constraint(model, e25, -(1.25733634311512*x[38])^(-0.71) + x[42] == 0)
    @constraint(model, e26, -(0.00908173562058528*x[38])^(-0.8) + x[43] == 0)
    @constraint(model, e27, -(124.31328320802*x[38])^(-0.95) + x[44] == 0)

    @constraint(model, e28, -(0.674 + 0.326/x[41])^0.123595505617978 + 3.97*x[17] == 0)
    @constraint(model, e29, -(0.557 + 0.443/x[42])^0.408450704225352 + 3.33*x[18] == 0)
    @constraint(model, e30, -(0.00900000000000001 + 0.991/x[43])^0.25 + 1.67*x[19] == 0)
    @constraint(model, e31, -(0.99202 + 0.00798/x[44])^0.0526315789473684 + 1.84*x[20] == 0)

    @constraint(model, e32, -(0.326 + 0.674*x[41])^0.123595505617978 + 3.97*x[21] == 0)
    @constraint(model, e33, -(0.443 + 0.557*x[42])^0.408450704225352 + 3.33*x[22] == 0)
    @constraint(model, e34, -(0.991 + 0.00900000000000001*x[43])^0.25 + 1.67*x[23] == 0)
    @constraint(model, e35, -(0.00798 + 0.99202*x[44])^0.0526315789473684 + 1.84*x[24] == 0)

    @constraint(model, e36, -x[37]*x[21] + x[5] - x[17] == 0)
    @constraint(model, e37, -x[37]*x[22] + x[6] - x[18] == 0)
    @constraint(model, e38, -x[37]*x[23] + x[7] - x[19] == 0)
    @constraint(model, e39, -x[37]*x[24] + x[8] - x[20] == 0)

    @objective(model, Min, objvar)

    return model, x, objvar
end

model, x, objvar = build_chenery_model()

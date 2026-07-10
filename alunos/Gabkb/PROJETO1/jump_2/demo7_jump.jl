using JuMP

"""
    build_demo7_model(; optimizer=nothing, set_starts=true)

Modelo JuMP convertido do GAMS `demo7`.
Observação: o GAMS lista x1..x67, depois objvar, x69, x70, x71. Não há x68 no modelo original;
por compatibilidade de índice, x[68] é criado, mas não aparece em nenhuma restrição.
"""
function build_demo7_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:71])
    @variable(model, objvar)

    positive_idx = vcat(1:7, 15:55, 62:67)
    for i in positive_idx
        set_lower_bound(x[i], 0.0)
    end
    for i in 15:26
        set_upper_bound(x[i], 25000.0)
    end

    if set_starts
        for i in 1:71
            if has_lower_bound(x[i])
                set_start_value(x[i], max(1.0, lower_bound(x[i]) + 1.0))
            else
                set_start_value(x[i], 0.0)
            end
        end
        set_start_value(x[56], 100.0)
        set_start_value(x[57], 200.0)
        set_start_value(x[58], 125.0)
        set_start_value(x[59], 350.0)
        set_start_value(x[60], 70.0)
        set_start_value(x[61], 120.0)
        set_start_value(objvar, 0.0)
    end

    @objective(model, Min, objvar)

    # e1..e12: limites de capacidade.
    @constraint(model, e1,  x[1] + x[2] + x[3] + x[4] <= 4000.0)
    @constraint(model, e2,  x[1] + x[2] + x[3] + x[4] <= 4000.0)
    @constraint(model, e3,  x[1] + 0.5*x[2] + x[3] + x[4] + 0.5*x[5] <= 4000.0)
    @constraint(model, e4,  x[1] + x[3] + x[4] + x[5] <= 4000.0)
    @constraint(model, e5,  x[1] + 0.25*x[4] + x[5] + 0.25*x[6] <= 4000.0)
    @constraint(model, e6,  x[5] + x[6] <= 4000.0)
    @constraint(model, e7,  x[5] + x[6] + 0.75*x[7] <= 4000.0)
    @constraint(model, e8,  x[5] + x[6] + x[7] <= 4000.0)
    @constraint(model, e9,  x[5] + x[6] + x[7] <= 4000.0)
    @constraint(model, e10, x[5] + 0.5*x[6] + x[7] <= 4000.0)
    @constraint(model, e11, 0.5*x[1] + 0.25*x[2] + 0.25*x[3] + 0.5*x[4] + 0.75*x[5] + 0.75*x[7] <= 4000.0)
    @constraint(model, e12, x[1] + x[2] + x[3] + x[4] <= 4000.0)

    # e13..e24
    A = [
        [1.72, 4.5, 0.75, 5.16, 0.0, 0.0, 0.0],
        [0.5, 1.0, 0.75, 5.0, 0.0, 0.0, 0.0],
        [1.0, 8.0, 0.75, 5.0, 5.0, 0.0, 0.0],
        [1.0, 0.0, 16.0, 19.58, 5.0, 0.0, 0.0],
        [17.16, 0.0, 0.0, 2.42, 9.0, 4.3, 0.0],
        [2.34, 0.0, 0.0, 0.0, 2.0, 5.04, 0.0],
        [0.0, 0.0, 0.0, 0.0, 1.5, 7.16, 17.0],
        [0.0, 0.0, 0.0, 0.0, 2.0, 7.97, 15.0],
        [0.0, 0.0, 0.0, 0.0, 1.0, 4.41, 12.0],
        [0.0, 0.0, 0.0, 0.0, 26.0, 1.12, 7.0],
        [2.43, 2.5, 7.5, 11.16, 12.0, 0.0, 6.0],
        [1.35, 7.5, 0.75, 4.68, 0.0, 0.0, 0.0]
    ]
    @constraint(model, profit_bal[r in 1:12],
        sum(A[r][j]*x[j] for j in 1:7) - x[14+r] - x[26+r] + 2*x[39] + 2*x[40] <= 0.0)

    @constraint(model, e25, x[5] + x[6] + x[7] - 2*x[39] - 2*x[40] - x[48] <= 0.0)
    @constraint(model, e26, x[1] + x[2] + x[3] + x[4] - 2*x[39] - 2*x[40] - x[49] <= 0.0)

    @constraint(model, e27, x[13] - 3*sum(x[i] for i in 15:26) == 0.0)
    @constraint(model, e28,
        -(225*x[50] - 0.0462962962962963*x[50]^2 - 0.555555555555555*x[51]^2 +
          700*x[51] - 0.178571428571429*x[52]^2 + 250*x[52] -
          0.166666666666667*x[53]^2 + 700*x[53] - 0.0368421052631579*x[54]^2 +
          210*x[54] - 0.2*x[55]^2 + 220*x[55]) + x[9] - 40*x[62] - 300*x[63] - 60*x[64] == 0.0)
    @constraint(model, e29, x[12] - 4*sum(x[i] for i in 27:38) == 0.0)
    @constraint(model, e30, -x[10] - x[11] - x[12] - x[13] + x[14] == 0.0)

    @constraint(model, e31, -x[41] + x[50] - x[65] == 0.0)
    @constraint(model, e32, -x[43] + x[51] - x[66] == 0.0)
    @constraint(model, e33, -x[44] + x[52] + x[62] == 0.0)
    @constraint(model, e34, -x[45] + x[53] + x[63] == 0.0)
    @constraint(model, e35, -x[46] + x[54] - x[67] == 0.0)
    @constraint(model, e36, -x[47] + x[55] + x[64] == 0.0)

    @constraint(model, e37,
        -0.0916666666666667*x[1] - 0.0783333333333333*x[2] - 0.0883333333333333*x[3] -
        0.176666666666667*x[4] - 0.211666666666667*x[5] - 0.1*x[6] - 0.19*x[7] -
        0.00666666666666667*x[39] - 0.00666666666666667*x[40] + x[70] == 0.0)

    @constraint(model, e38, -1.5*x[1] + x[41] == 0.0)
    @constraint(model, e39, -6*x[2] + x[42] == 0.0)
    @constraint(model, e40, -x[3] + x[43] == 0.0)
    @constraint(model, e41, -3*x[4] + x[44] == 0.0)
    @constraint(model, e42, -1.5*x[5] + x[45] == 0.0)
    @constraint(model, e43, -2*x[6] + x[46] == 0.0)
    @constraint(model, e44, -3*x[7] + x[47] == 0.0)
    @constraint(model, e45, -100*x[41] - 200*x[43] - 125*x[44] - 350*x[45] - 70*x[46] - 120*x[47] + x[69] == 0.0)
    @constraint(model, e46, -10*x[1] - 5*x[3] - 50*x[4] - 80*x[5] - 5*x[6] - 50*x[7] + x[10] == 0.0)
    @constraint(model, e47, x[11] - 40*x[48] - 40*x[49] == 0.0)
    @constraint(model, e48, 6*x[2] - 1.3*x[39] - 2*x[40] >= 0.0)
    @constraint(model, e49, 1.75*x[1] - 1.6*x[39] - 0.8*x[40] >= 0.0)
    @constraint(model, e50, -x[8] - x[9] - x[13] + x[14] == 0.0)
    @constraint(model, e51, -40*x[62] - 300*x[63] - 60*x[64] + 140*x[65] + 270*x[66] + 85*x[67] + x[71] == 0.0)
    @constraint(model, e52, 0.0462962962962963*x[50] + x[56] == 225.0)
    @constraint(model, e53, 0.555555555555555*x[51] + x[57] == 700.0)
    @constraint(model, e54, 0.178571428571429*x[52] + x[58] == 250.0)
    @constraint(model, e55, 0.166666666666667*x[53] + x[59] == 700.0)
    @constraint(model, e56, 0.0368421052631579*x[54] + x[60] == 210.0)
    @constraint(model, e57, 0.2*x[55] + x[61] == 220.0)
    @constraint(model, e58,
        -(225*x[50] - 0.0231481481481481*x[50]^2 - 0.277777777777778*x[51]^2 +
          700*x[51] - 0.0892857142857143*x[52]^2 + 250*x[52] -
          0.0833333333333333*x[53]^2 + 700*x[53] - 0.0184210526315789*x[54]^2 +
          210*x[54] - 0.1*x[55]^2 + 220*x[55]) + x[14] - 40*x[62] - 300*x[63] -
          60*x[64] + 140*x[65] + 270*x[66] + 85*x[67] - objvar == 0.0)

    return model
end

model = build_demo7_model()

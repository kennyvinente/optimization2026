using JuMP

function build_ex5_3_3_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:62] >= 0)
    @variable(model, objvar)

    for i in 1:32
        set_upper_bound(x[i], 600.0)
    end
    for i in 33:62
        set_upper_bound(x[i], 1.0)
    end

    @constraint(model, e1, x[1] + x[2] + x[3] + x[4] + x[5] == 600.0)
    @constraint(model, e2, -x[1] + x[6] - x[17] - x[26] == 0.0)
    @constraint(model, e3, -x[2] - x[11] + x[15] - x[27] == 0.0)
    @constraint(model, e4, -x[3] - x[12] - x[21] + x[24] == 0.0)
    @constraint(model, e5, x[7] - x[8] - x[9] == 0.0)
    @constraint(model, e6, x[10] - x[11] - x[12] - x[13] - x[14] == 0.0)
    @constraint(model, e7, x[16] - x[17] - x[18] - x[19] == 0.0)
    @constraint(model, e8, x[20] - x[21] - x[22] - x[23] == 0.0)
    @constraint(model, e9, x[25] - x[26] - x[27] - x[28] - x[29] == 0.0)
    @constraint(model, e10, x[30] - x[31] - x[32] == 0.0)

    @constraint(model, e11, x[7]*x[37] - 0.85*x[6]*x[33] == 0.0)
    @constraint(model, e12, x[16]*x[48] - 0.85*x[15]*x[44] == 0.0)
    @constraint(model, e13, x[25]*x[59] - x[24]*x[55] == 0.0)
    @constraint(model, e14, x[10]*x[40] - x[6]*x[34] == 0.0)
    @constraint(model, e15, x[20]*x[51] - 0.85*x[15]*x[45] == 0.0)
    @constraint(model, e16, x[30]*x[62] - 0.85*x[24]*x[56] == 0.0)
    @constraint(model, e17, x[6]*x[33] - x[7]*x[37] - x[10]*x[39] == 0.0)
    @constraint(model, e18, x[6]*x[34] - x[7]*x[38] - x[10]*x[40] == 0.0)
    @constraint(model, e19, x[6]*x[35] - x[10]*x[41] == 0.0)
    @constraint(model, e20, x[6]*x[36] - x[10]*x[42] == 0.0)
    @constraint(model, e21, x[15]*x[43] - x[16]*x[47] == 0.0)
    @constraint(model, e22, x[15]*x[44] - x[16]*x[48] - x[20]*x[50] == 0.0)
    @constraint(model, e23, x[15]*x[45] - x[16]*x[49] - x[20]*x[51] == 0.0)
    @constraint(model, e24, x[15]*x[46] - x[20]*x[52] == 0.0)
    @constraint(model, e25, x[24]*x[53] - x[25]*x[57] == 0.0)
    @constraint(model, e26, x[24]*x[54] - x[25]*x[58] == 0.0)
    @constraint(model, e27, x[24]*x[55] - x[25]*x[59] - x[30]*x[61] == 0.0)
    @constraint(model, e28, x[24]*x[56] - x[25]*x[60] - x[30]*x[62] == 0.0)

    @constraint(model, e29, x[17]*x[47] + x[26]*x[57] - x[6]*x[33] + 0.25*x[1] == 0.0)
    @constraint(model, e30, x[17]*x[48] + x[26]*x[58] - x[6]*x[34] + 0.333*x[1] == 0.0)
    @constraint(model, e31, x[17]*x[49] + x[26]*x[59] - x[6]*x[35] + 0.167*x[1] == 0.0)
    @constraint(model, e32, x[26]*x[60] - x[6]*x[36] + 0.25*x[1] == 0.0)
    @constraint(model, e33, x[11]*x[39] + x[27]*x[57] - x[15]*x[43] + 0.25*x[2] == 0.0)
    @constraint(model, e34, x[11]*x[40] + x[27]*x[58] - x[15]*x[44] + 0.333*x[2] == 0.0)
    @constraint(model, e35, x[11]*x[41] + x[27]*x[59] - x[15]*x[45] + 0.167*x[2] == 0.0)
    @constraint(model, e36, x[11]*x[42] + x[27]*x[60] - x[15]*x[46] + 0.25*x[2] == 0.0)
    @constraint(model, e37, x[12]*x[39] - x[24]*x[53] + 0.25*x[3] == 0.0)
    @constraint(model, e38, x[12]*x[40] + x[21]*x[50] - x[24]*x[54] + 0.333*x[3] == 0.0)
    @constraint(model, e39, x[12]*x[41] + x[21]*x[51] - x[24]*x[55] + 0.167*x[3] == 0.0)
    @constraint(model, e40, x[12]*x[42] + x[21]*x[52] - x[24]*x[56] + 0.25*x[3] == 0.0)
    @constraint(model, e41, x[8]*x[37] + x[13]*x[39] + x[18]*x[47] + x[28]*x[57] + 0.25*x[4] == 50.0)
    @constraint(model, e42, x[8]*x[38] + x[13]*x[40] + x[18]*x[48] + x[22]*x[50] + x[28]*x[58] + 0.222*x[4] == 100.0)
    @constraint(model, e43, x[13]*x[41] + x[18]*x[49] + x[22]*x[51] + x[28]*x[59] + x[31]*x[61] + 0.167*x[4] == 40.0)
    @constraint(model, e44, x[13]*x[42] + x[22]*x[52] + x[28]*x[60] + x[31]*x[62] + 0.25*x[4] == 100.0)

    @constraint(model, e45, x[33] + x[34] + x[35] + x[36] == 1.0)
    @constraint(model, e46, x[37] + x[38] == 1.0)
    @constraint(model, e47, x[39] + x[40] + x[41] + x[42] == 1.0)
    @constraint(model, e48, x[43] + x[44] + x[45] + x[46] == 1.0)
    @constraint(model, e49, x[47] + x[48] + x[49] == 1.0)
    @constraint(model, e50, x[50] + x[51] + x[52] == 1.0)
    @constraint(model, e51, x[53] + x[54] + x[55] + x[56] == 1.0)
    @constraint(model, e52, x[57] + x[58] + x[59] + x[60] == 1.0)
    @constraint(model, e53, x[61] + x[62] == 1.0)

    @constraint(model, e54,
        -((0.00132223 + 0.0016446*x[33] + 0.0018611*x[34] + 0.001262*x[35]) * x[6] +
          (0.0015625*x[43] + 0.0091604*x[44] + 0.0076758*x[45] - 9.40700000000017e-5) * x[15] +
          (0.00457315 - 0.001748*x[53] - 0.0002583*x[54] - 0.0004691*x[55]) * x[24]) + objvar == 1.68776
    )

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_ex5_3_3_model()
for i in 1:62
    @eval $(Symbol(:x, i)) = x[$i]
end

using JuMP

model = Model()

@variable(model, objvar)
@variable(model, x[2:65])

# Positive variables from GAMS
for i in vcat(2:29, 31, 33:65)
    set_lower_bound(x[i], 0.0)
end

# Explicit bounds from GAMS
set_lower_bound(x[30], 326.0)
set_upper_bound(x[31], 304.0)
set_lower_bound(x[32], 326.0)
set_upper_bound(x[33], 304.0)
for i in 34:37
    set_upper_bound(x[i], 1000.0)
end

# Initial levels from GAMS
set_start_value(x[2], 396.0)
set_start_value(x[30], 390.0)
set_start_value(x[32], 360.0)
set_start_value(x[34], 410.0)
set_start_value(x[36], 380.0)
set_start_value(x[38], 76.0)
set_start_value(x[39], 1.0)
set_start_value(x[40], 26.0)
set_start_value(x[41], 1.0)

# Aliases
for i in 2:65
    @eval $(Symbol("x", i)) = x[$i]
end

@constraint(model, -(0.4*((0.003375*x[30] - 1.15398)*x[2] + (0.000893*x[31] - 0.30630793)*x[3] + (0.004458*x[32] - 1.57608132)*x[4] + (0.003176*x[33] - 1.08593792)*x[5]
    + 31.8928571428571*x[14]/(x[30] - x[36]) + 31.8928571428571*x[15]/(1 + x[31] - x[37]) + 31.8928571428571*x[16]/(x[32] - x[34]) + 31.8928571428571*x[17]/(1 + x[33] - x[35])
    + 31.8928571428571*x[26]/x[38] + 31.8928571428571*x[27]/(1 + x[39]) + 31.8928571428571*x[28]/x[40] + 31.8928571428571*x[29]/(1 + x[41])
    + 31.8928571428571*x[18]/(421 - x[34]) + 31.8928571428571*x[19]/(421 - x[35]) + 31.8928571428571*x[20]/(421 - x[36]) + 31.8928571428571*x[21]/(421 - x[37])
    + 31.8928571428571*x[22]/(373 - x[34]) + 31.8928571428571*x[23]/(373 - x[35]) + 31.8928571428571*x[24]/(373 - x[36]) + 31.8928571428571*x[25]/(373 - x[37]))
    + 12.95216*(x[18]+x[19]+x[20]+x[21]) + 4.75228*(x[22]+x[23]+x[24]+x[25]) + 2.418*(x[26]+x[27]+x[28]+x[29])) + objvar == 67.56864)

@constraint(model, -0.666666666666667*sqrt((x[30]-305)*(x[30]-325)) - 0.333333333333333*x[30] + x[38] - x[42] + x[46] == -105)
@constraint(model, -0.666666666666667*sqrt((x[31]-305)*(x[31]-325)) - 0.333333333333333*x[31] + x[39] - x[43] + x[47] == -105)
@constraint(model, -0.666666666666667*sqrt((x[32]-305)*(x[32]-325)) - 0.333333333333333*x[32] + x[40] - x[44] + x[48] == -105)
@constraint(model, -0.666666666666667*sqrt((x[33]-305)*(x[33]-325)) - 0.333333333333333*x[33] + x[41] - x[45] + x[49] == -105)

@constraint(model, x[42] + x[50] + x[54] <= 0)
@constraint(model, x[43] + x[51] + x[55] <= 1500)
@constraint(model, x[44] + x[52] + x[56] <= 0)
@constraint(model, x[45] + x[53] + x[57] <= 1500)
@constraint(model, x[46] + x[58] + x[62] <= 0)
@constraint(model, x[47] + x[59] + x[63] <= 1500)
@constraint(model, x[48] + x[60] + x[64] <= 0)
@constraint(model, x[49] + x[61] + x[65] <= 1500)

@constraint(model, x[30] + x[34] + x[38] <= 1500)
@constraint(model, x[31] + x[35] + x[39] <= 0)
@constraint(model, x[32] + x[36] + x[40] <= 1500)
@constraint(model, x[33] + x[37] + x[41] <= 0)

@constraint(model, 0.9*x[3] - x[5] == 0)
@constraint(model, 0.2*x[2] - x[4] == 0)
@constraint(model, x[2] + x[3] == 396)
@constraint(model, x[2] <= 1500)
@constraint(model, x[3] <= 0)
@constraint(model, x[4] <= 1500)
@constraint(model, x[5] <= 0)

@constraint(model, x[10] - 0.0225*x[30] - x[58] + x[62] == 24.7068)
@constraint(model, x[11] - 0.013*x[31] - x[59] + x[63] == 20.54087)
@constraint(model, x[12] - 0.0043*x[32] - x[60] + x[64] == 2.239778)
@constraint(model, x[13] - 0.0156*x[33] - x[61] + x[65] == 29.766048)
@constraint(model, x[6] - x[10] == 0)
@constraint(model, x[7] - x[11] == 0)
@constraint(model, x[8] - x[12] == 0)
@constraint(model, x[9] - x[13] == 0)
@constraint(model, x[10] - x[14] - x[26] == 0)
@constraint(model, x[11] - x[15] - x[27] == 0)
@constraint(model, x[12] - x[16] - x[28] == 0)
@constraint(model, x[13] - x[17] - x[29] == 0)
@constraint(model, x[6] - x[16] - x[18] - x[22] == 0)
@constraint(model, x[7] - x[17] - x[19] - x[23] == 0)
@constraint(model, x[8] - x[14] - x[20] - x[24] == 0)
@constraint(model, x[9] - x[15] - x[21] - x[25] == 0)

@constraint(model, -x[30] <= -341.92)
@constraint(model, -x[31] <= 1156.99)
@constraint(model, -x[32] <= -353.54)
@constraint(model, -x[33] <= 1158.08)
for i in 34:37
    @constraint(model, x[i] <= 411)
end
@constraint(model, -1.028*x[30] + x[34] - x[50] + x[54] == -341.95276)
@constraint(model, -1.05*x[31] + x[35] - x[51] + x[55] == -347.9205)
@constraint(model, -1.029*x[32] + x[36] - x[52] + x[56] == -355.03666)
@constraint(model, -1.005*x[33] + x[37] - x[53] + x[57] == -334.4486)
@constraint(model, -x[30] + x[36] <= -10)
@constraint(model, -x[31] + x[37] <= 1490)
@constraint(model, -x[32] + x[34] <= 1490)
@constraint(model, -x[33] + x[35] <= 1490)
for i in 34:37
    @constraint(model, x[i] <= 1863)
end
@constraint(model, x[14] <= 1500)
@constraint(model, x[15] <= 0)
@constraint(model, x[16] <= 0)
@constraint(model, x[17] <= 0)
@constraint(model, x[18] <= 1500)
for i in 19:25
    @constraint(model, x[i] <= 0)
end
@constraint(model, x[26] <= 1500)
@constraint(model, x[27] <= 0)
@constraint(model, x[28] <= 1500)
@constraint(model, x[29] <= 0)
@constraint(model, x[6] + x[10] <= 1500)
@constraint(model, x[7] + x[11] <= 0)
@constraint(model, x[8] + x[12] <= 1500)
@constraint(model, x[9] + x[13] <= 0)

@objective(model, Min, objvar)

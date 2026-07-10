using JuMP

# Modelo: ramsey
# Convertido de GAMS Convert para JuMP

model = Model()

@variable(model, objvar)
@variable(model, x[1:33])

fix(x[1], 3.0; force = true)
fix(x[23], 0.05; force = true)

for i in 2:11
    set_lower_bound(x[i], 3.0)
end
for i in 12:22
    set_lower_bound(x[i], 0.95)
end

bounds = Dict(
    24 => (0.05, 0.0575),
    25 => (0.05, 0.066125),
    26 => (0.05, 0.07604375),
    27 => (0.05, 0.0874503125),
    28 => (0.05, 0.100567859375),
    29 => (0.05, 0.11565303828125),
    30 => (0.05, 0.133000994023437),
    31 => (0.05, 0.152951143126953),
    32 => (0.05, 0.175893814595996),
    33 => (0.05, 0.202277886785395),
)
for (i, (lo, up)) in bounds
    set_lower_bound(x[i], lo)
    set_upper_bound(x[i], up)
end

set_start_value(x[1], 3.0)
set_start_value(x[23], 0.05)
set_start_value(objvar, 0.0)

@NLobjective(model, Min, objvar)

@NLconstraint(model, e1,  0.759835685651593*x[1]^0.25  - x[12] - x[23] == 0)
@NLconstraint(model, e2,  0.77686866556676*x[2]^0.25   - x[13] - x[24] == 0)
@NLconstraint(model, e3,  0.794283468039448*x[3]^0.25  - x[14] - x[25] == 0)
@NLconstraint(model, e4,  0.812088652256959*x[4]^0.25  - x[15] - x[26] == 0)
@NLconstraint(model, e5,  0.830292969275008*x[5]^0.25  - x[16] - x[27] == 0)
@NLconstraint(model, e6,  0.848905366318769*x[6]^0.25  - x[17] - x[28] == 0)
@NLconstraint(model, e7,  0.867934991180342*x[7]^0.25  - x[18] - x[29] == 0)
@NLconstraint(model, e8,  0.88739119671479*x[8]^0.25   - x[19] - x[30] == 0)
@NLconstraint(model, e9,  0.907283545436972*x[9]^0.25  - x[20] - x[31] == 0)
@NLconstraint(model, e10, 0.92762181422141*x[10]^0.25  - x[21] - x[32] == 0)
@NLconstraint(model, e11, 0.948415999107521*x[11]^0.25 - x[22] - x[33] == 0)

@NLconstraint(model, e12, -x[1] + x[2] - x[23] == 0)
@NLconstraint(model, e13, -x[2] + x[3] - x[24] == 0)
@NLconstraint(model, e14, -x[3] + x[4] - x[25] == 0)
@NLconstraint(model, e15, -x[4] + x[5] - x[26] == 0)
@NLconstraint(model, e16, -x[5] + x[6] - x[27] == 0)
@NLconstraint(model, e17, -x[6] + x[7] - x[28] == 0)
@NLconstraint(model, e18, -x[7] + x[8] - x[29] == 0)
@NLconstraint(model, e19, -x[8] + x[9] - x[30] == 0)
@NLconstraint(model, e20, -x[9] + x[10] - x[31] == 0)
@NLconstraint(model, e21, -x[10] + x[11] - x[32] == 0)
@NLconstraint(model, e22, 0.03*x[11] - x[33] <= 0)

@NLconstraint(model, e23,
    -(0.95*log(x[12]) +
      0.9025*log(x[13]) +
      0.857375*log(x[14]) +
      0.81450625*log(x[15]) +
      0.7737809375*log(x[16]) +
      0.735091890625*log(x[17]) +
      0.69833729609375*log(x[18]) +
      0.663420431289062*log(x[19]) +
      0.630249409724609*log(x[20]) +
      0.598736939238379*log(x[21]) +
      11.3760018455292*log(x[22])) - objvar == 0)

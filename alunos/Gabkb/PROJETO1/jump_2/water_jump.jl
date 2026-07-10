using JuMP
using Ipopt

model = Model(Ipopt.Optimizer)

@variable(model, x[1:41])
@variable(model, objvar)

# Positive Variables do GAMS
set_lower_bound(x[37], 0.0)
set_lower_bound(x[38], 0.0)

# Bounds
for i in 15:28
    set_lower_bound(x[i], 0.15)
    set_upper_bound(x[i], 2.0)
end

set_lower_bound(x[29], 6.5)
set_lower_bound(x[30], 3.25)
set_lower_bound(x[31], 16.58)
set_lower_bound(x[32], 14.92)
set_lower_bound(x[33], 12.925)
set_lower_bound(x[34], 12.26)
set_lower_bound(x[35], 8.76)
set_lower_bound(x[36], 16.08)

set_upper_bound(x[37], 2.5)
set_upper_bound(x[38], 6.0)

# Initial values
for i in 15:28
    set_start_value(x[i], 0.547722557505166)
end

set_start_value(x[29], 7.5)
set_start_value(x[30], 4.25)
set_start_value(x[31], 17.58)
set_start_value(x[32], 15.92)
set_start_value(x[33], 13.925)
set_start_value(x[34], 13.26)
set_start_value(x[35], 9.76)
set_start_value(x[36], 17.08)
set_start_value(x[37], 0.961470588235294)
set_start_value(x[38], 2.30752941176471)

# Equações
@constraint(model, e1,  -x[1] - x[2] - x[3] + x[37] == 0)
@constraint(model, e2,  -x[4] - x[5] - x[6] - x[7] + x[38] == 0)
@constraint(model, e3,   x[1] + x[4] - x[8] - x[9] - x[10] - x[11] == 1.212)
@constraint(model, e4,   x[2] + x[8] + x[12] == 0.452)
@constraint(model, e5,   x[9] - x[12] + x[13] == 0.245)
@constraint(model, e6,   x[5] + x[10] - x[13] - x[14] == 0.652)
@constraint(model, e7,   x[6] + x[14] == 0.252)
@constraint(model, e8,   x[3] + x[7] + x[11] == 0.456)

@NLconstraint(model, e9,  -1.5722267648148 * abs(x[1])  * x[1]  / x[15]^5.33 + x[29] - x[31] == 0)
@NLconstraint(model, e10, -1.32004857865156 * abs(x[2])  * x[2]  / x[16]^5.33 + x[29] - x[32] == 0)
@NLconstraint(model, e11, -2.57705917665854 * abs(x[3])  * x[3]  / x[17]^5.33 + x[29] - x[36] == 0)
@NLconstraint(model, e12, -2.06257339263358 * abs(x[4])  * x[4]  / x[18]^5.33 + x[30] - x[31] == 0)
@NLconstraint(model, e13, -2.40235218067626 * abs(x[5])  * x[5]  / x[19]^5.33 + x[30] - x[34] == 0)
@NLconstraint(model, e14, -1.339 * abs(x[6]) * x[6] / x[20]^5.33 + x[30] - x[35] == 0)
@NLconstraint(model, e15, -1.37419139860501 * abs(x[7])  * x[7]  / x[21]^5.33 + x[30] - x[36] == 0)
@NLconstraint(model, e16, -1.2916134290104  * abs(x[8])  * x[8]  / x[22]^5.33 + x[31] - x[32] == 0)
@NLconstraint(model, e17, -1.60230396616872 * abs(x[9])  * x[9]  / x[23]^5.33 + x[31] - x[33] == 0)
@NLconstraint(model, e18, -1.339 * abs(x[10]) * x[10] / x[24]^5.33 + x[31] - x[34] == 0)
@NLconstraint(model, e19, -2.14329116080854 * abs(x[11]) * x[11] / x[25]^5.33 + x[31] - x[36] == 0)
@NLconstraint(model, e20, -1.24561882211213 * abs(x[12]) * x[12] / x[26]^5.33 - x[32] + x[33] == 0)
@NLconstraint(model, e21, -1.15157500841239 * abs(x[13]) * x[13] / x[27]^5.33 - x[33] + x[34] == 0)
@NLconstraint(model, e22, -2.06257339263358 * abs(x[14]) * x[14] / x[28]^5.33 + x[34] - x[35] == 0)

@NLconstraint(model, e23, -(1.02 * x[37] * (x[29] - 6.5) + 1.02 * x[38] * (x[30] - 3.25)) + x[39] == 0)

@NLconstraint(model, e24,
    -0.069 * (
        1526.43375224737 * x[15]^1.29 +
        1281.60056179763 * x[16]^1.29 +
        2501.99920063936 * x[17]^1.29 +
        2002.49843945008 * x[18]^1.29 +
        2332.38075793812 * x[19]^1.29 +
        1300 * x[20]^1.29 +
        1334.16640641263 * x[21]^1.29 +
        1253.99362039845 * x[22]^1.29 +
        1555.6349186104 * x[23]^1.29 +
        1300 * x[24]^1.29 +
        2080.86520466848 * x[25]^1.29 +
        1209.33866224478 * x[26]^1.29 +
        1118.03398874989 * x[27]^1.29 +
        2002.49843945008 * x[28]^1.29
    ) + x[40] == 0
)

@constraint(model, e25, -0.2 * x[37] - 0.17 * x[38] + x[41] == 0)
@constraint(model, e26, -10 * x[39] - x[40] - 10 * x[41] + objvar == 0)

@objective(model, Min, objvar)

optimize!(model)

println("Status: ", termination_status(model))
println("Objective: ", objective_value(model))
for i in 1:41
    println("x", i, " = ", value(x[i]))
end
println("objvar = ", value(objvar))

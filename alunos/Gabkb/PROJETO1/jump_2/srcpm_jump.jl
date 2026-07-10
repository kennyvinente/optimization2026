using JuMP
using Ipopt

model = Model(Ipopt.Optimizer)

# Variáveis
@variable(model, x[1:39])
@variable(model, objvar)

# Positive Variables: x1..x33
for i in 1:33
    set_lower_bound(x[i], 0.0)
end

# Bounds
set_upper_bound(x[23], 13.6)
set_upper_bound(x[24], 1.1)
set_upper_bound(x[25], 1.0)
set_upper_bound(x[26], 16.2)
set_upper_bound(x[27], 8.9)
set_upper_bound(x[28], 4.4)
set_upper_bound(x[29], 3.1)
set_upper_bound(x[30], 1.7)
set_upper_bound(x[31], 1.9)

set_lower_bound(x[34], 2.0)
set_lower_bound(x[35], 2.0)
set_lower_bound(x[36], 2.0)
set_lower_bound(x[37], 2.0)
set_lower_bound(x[38], 2.0)

# Initial values
set_start_value(x[1], 3.1)
set_start_value(x[3], 13.6)
set_start_value(x[5], 1.1)
set_start_value(x[7], 1.0)
set_start_value(x[9], 16.4244058299284)
set_start_value(x[11], 8.9)
set_start_value(x[13], 4.4)
set_start_value(x[15], 7.1)
set_start_value(x[16], 0.8)
set_start_value(x[17], 5.56103683518173)
set_start_value(x[18], 0.312071787775987)
set_start_value(x[19], 1.73896316481828)
set_start_value(x[20], 2.5)
set_start_value(x[21], 2.7)
set_start_value(x[23], 13.6)
set_start_value(x[24], 1.1)
set_start_value(x[25], 1.0)
set_start_value(x[26], 15.7244058299284)
set_start_value(x[27], 8.9)
set_start_value(x[28], 4.4)
set_start_value(x[29], 3.1)
set_start_value(x[30], 0.928008053710258)
set_start_value(x[31], 0.268195340806014)
set_start_value(x[32], 2.78989137704229)
set_start_value(x[33], 6.47831105055452)
set_start_value(x[34], 12.8)
set_start_value(x[35], 13.8)
set_start_value(x[36], 8.3)
set_start_value(x[37], 4.2)
set_start_value(x[38], 8.6)
set_start_value(x[39], 1560.6691675193)

# Restrições >=
@constraint(model, -x[3] - x[4] + x[23] >= 0)
@constraint(model, -x[5] - x[6] + x[24] >= 0)
@constraint(model, -x[7] - x[8] + x[25] >= 0)
@constraint(model, -x[9] - x[10] + x[26] >= -0.7)
@constraint(model, -x[11] - x[12] + x[27] >= 0)
@constraint(model, -x[13] - x[14] + x[28] >= 0)
@constraint(model, -x[1] - x[2] + x[29] >= 0)

@constraint(model,
    0.35*x[3] + 0.34*x[4] + 0.5*x[5] + 0.49*x[6] + 0.68*x[7] + 0.67*x[8]
    - x[17] - x[18] + 0.99*x[21] + 0.99*x[22] - x[32] >= 0
)

@constraint(model,
    0.38*x[9] + 0.38*x[10] + 0.48*x[11] + 0.47*x[12] + 0.66*x[13] + 0.65*x[14]
    - x[19] - x[20] - x[21] - x[22] - x[33] >= 0
)

@constraint(model,
    0.2*x[1] + 0.2*x[2] + 0.96*x[15] + 0.96*x[16] + 0.67*x[17] + 0.36*x[18]
    + 0.61*x[19] + 0.25*x[20] - x[30] - x[34] >= 0
)

@constraint(model,
    0.28*x[3] + 0.28*x[4] + 0.25*x[5] + 0.25*x[6] + 0.2*x[7] + 0.2*x[8]
    + 0.26*x[9] + 0.26*x[10] + 0.23*x[11] + 0.23*x[12] + 0.18*x[13] + 0.18*x[14]
    + 0.07*x[17] + 0.18*x[18] + 0.02*x[19] + 0.1*x[20] + x[30] + 0.93*x[31] - x[35] >= -0.5
)

@constraint(model,
    0.8*x[1] + 0.8*x[2] + 0.35*x[3] + 0.35*x[4] + 0.23*x[5] + 0.23*x[6]
    + 0.1*x[7] + 0.1*x[8] + 0.33*x[9] + 0.33*x[10] + 0.27*x[11] + 0.27*x[12]
    + 0.14*x[13] + 0.14*x[14] - x[15] - x[16] + 0.04*x[17] + 0.03*x[18]
    + 0.06*x[19] + 0.04*x[20] - x[31] - x[36] >= 0
)

@constraint(model, 0.23*x[17] + 0.42*x[18] + x[32] - x[37] >= 0)
@constraint(model, 0.3*x[19] + 0.6*x[20] + x[33] - x[38] >= -0.1)

# Restrições <=
@constraint(model, x[1] <= 3.4)
@constraint(model, x[2] <= 0)
@constraint(model, x[21] <= 2.7)
@constraint(model, x[22] <= 0.3)
@constraint(model, x[3] + x[5] + x[7] + x[9] + x[11] + x[13] <= 50.5)
@constraint(model, x[4] + x[6] + x[8] + x[10] + x[12] + x[14] <= 7.5)
@constraint(model, x[15] <= 7.1)
@constraint(model, x[16] <= 0.8)
@constraint(model, x[17] + x[19] <= 7.3)
@constraint(model, x[18] + x[20] <= 2.9)
@constraint(model, -0.83*x[17] + x[19] <= 3.9)
@constraint(model, x[20] <= 2.5)

# Igualdades
@constraint(model,
    -0.45*x[3] - 0.5*x[4] - 0.45*x[5] - 0.5*x[6] - 0.45*x[7] - 0.5*x[8]
    - 0.5*x[9] - 0.55*x[10] - 0.5*x[11] - 0.55*x[12] - 0.5*x[13] - 0.55*x[14]
    - 0.41*x[15] - 0.5*x[16] - 0.27*x[17] - 0.45*x[18] - 0.32*x[19] - 0.28*x[20]
    - 0.9*x[21] - x[22] - 32*x[23] - 32*x[24] - 32*x[25] - 32*x[26] - 32*x[27]
    - 32*x[28] - 32*x[29] + 0.3*x[30] + x[39] == 0
)

@NLconstraint(model,
    -(-3865470.56640001*x[34]^(-4) - 5130022.82472*x[35]^(-4)
      - 423446.8691225*x[36]^(-4)
      - 1808.40439881057*x[37]^(-2.33333333333333)
      - 17313.2956782741*x[38]^(-2.33333333333333))
    + x[39] - objvar == 0
)

@objective(model, Min, objvar)

optimize!(model)

println("Status: ", termination_status(model))
println("Objective: ", objective_value(model))
for i in 1:39
    println("x", i, " = ", value(x[i]))
end
println("objvar = ", value(objvar))

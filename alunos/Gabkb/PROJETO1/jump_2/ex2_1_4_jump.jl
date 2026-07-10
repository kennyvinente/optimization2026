# Arquivo convertido de GAMS Convert para JuMP
using JuMP


model = Model()

@variable(model, x[1:6] >= 0)
@variable(model, objvar)
set_upper_bound(x[1], 1.0)
set_upper_bound(x[4], 1.0)
set_upper_bound(x[5], 1.0)
set_upper_bound(x[6], 2.0)

set_start_value(x[2], 6.0)
set_start_value(x[4], 1.0)
set_start_value(x[5], 1.0)

@objective(model, Min, objvar)

@constraint(model, e1, -(6.5*x[1] - 0.5*x[1]^2) + x[2] + 2.0*x[3] + 3.0*x[4] + 2.0*x[5] + x[6] + objvar == 0.0)
@constraint(model, e2, x[1] + 2.0*x[2] + 8.0*x[3] + x[4] + 3.0*x[5] + 5.0*x[6] <= 16.0)
@constraint(model, e3, -8.0*x[1] - 4.0*x[2] - 2.0*x[3] + 2.0*x[4] + 4.0*x[5] - x[6] <= -1.0)
@constraint(model, e4, 2.0*x[1] + 0.5*x[2] + 0.2*x[3] - 3.0*x[4] - x[5] - 4.0*x[6] <= 24.0)
@constraint(model, e5, 0.2*x[1] + 2.0*x[2] + 0.1*x[3] - 4.0*x[4] + 2.0*x[5] + 2.0*x[6] <= 12.0)
@constraint(model, e6, -0.1*x[1] - 0.5*x[2] + 2.0*x[3] + 5.0*x[4] - 5.0*x[5] + 3.0*x[6] <= 3.0)

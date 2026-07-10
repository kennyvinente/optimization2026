# Arquivo convertido de GAMS Convert para JuMP
using JuMP


model = Model()

@variable(model, 0 <= x[1:5] <= 1)
@variable(model, objvar)

set_start_value(x[1], 1.0)
set_start_value(x[2], 1.0)
set_start_value(x[4], 1.0)

@objective(model, Min, objvar)

@constraint(model, e1,
    -(
        42.0*x[1]
        - 0.5*(100.0*x[1]^2 + 100.0*x[2]^2 + 100.0*x[3]^2 + 100.0*x[4]^2 + 100.0*x[5]^2)
        + 44.0*x[2] + 45.0*x[3] + 47.0*x[4] + 47.5*x[5]
    ) + objvar == 0.0
)

@constraint(model, e2, 20.0*x[1] + 12.0*x[2] + 11.0*x[3] + 7.0*x[4] + 4.0*x[5] <= 40.0)

# aliases úteis
x1, x2, x3, x4, x5 = x[1], x[2], x[3], x[4], x[5]

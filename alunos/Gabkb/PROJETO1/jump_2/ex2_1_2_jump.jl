# Arquivo convertido de GAMS Convert para JuMP
using JuMP


model = Model()

@variable(model, x[1:6] >= 0)
@variable(model, objvar)
for i in 1:5
    set_upper_bound(x[i], 1.0)
end

set_start_value(x[2], 1.0)
set_start_value(x[4], 1.0)
set_start_value(x[5], 1.0)
set_start_value(x[6], 20.0)

@objective(model, Min, objvar)

@constraint(model, e1,
    -(
        -0.5*(x[1]^2 + x[2]^2 + x[3]^2 + x[4]^2 + x[5]^2)
        - 10.5*x[1] - 7.5*x[2] - 3.5*x[3] - 2.5*x[4] - 1.5*x[5]
    ) + 10.0*x[6] + objvar == 0.0
)
@constraint(model, e2, 6.0*x[1] + 3.0*x[2] + 3.0*x[3] + 2.0*x[4] + x[5] <= 6.5)
@constraint(model, e3, 10.0*x[1] + 10.0*x[3] + x[6] <= 20.0)

# Arquivo convertido de GAMS Convert para JuMP
using JuMP


model = Model()

@variable(model, x[1:13] >= 0)
@variable(model, objvar)
for i in [1,2,3,4,5,6,7,8,9,13]
    set_upper_bound(x[i], 1.0)
end
for i in 1:9
    set_start_value(x[i], 1.0)
end
set_start_value(x[10], 3.0)
set_start_value(x[11], 3.0)
set_start_value(x[12], 3.0)
set_start_value(x[13], 1.0)

@objective(model, Min, objvar)

@constraint(model, e1,
    -(
        5.0*x[1] - 0.5*(10.0*x[1]^2 + 10.0*x[2]^2 + 10.0*x[3]^2 + 10.0*x[4]^2)
        + 5.0*x[2] + 5.0*x[3] + 5.0*x[4]
    ) + sum(x[i] for i in 5:13) + objvar == 0.0
)
@constraint(model, e2, 2.0*x[1] + 2.0*x[2] + x[10] + x[11] <= 10.0)
@constraint(model, e3, 2.0*x[1] + 2.0*x[3] + x[10] + x[12] <= 10.0)
@constraint(model, e4, 2.0*x[2] + 2.0*x[3] + x[11] + x[12] <= 10.0)
@constraint(model, e5, -8.0*x[1] + x[10] <= 0.0)
@constraint(model, e6, -8.0*x[2] + x[11] <= 0.0)
@constraint(model, e7, -8.0*x[3] + x[12] <= 0.0)
@constraint(model, e8, -2.0*x[4] - x[5] + x[10] <= 0.0)
@constraint(model, e9, -2.0*x[6] - x[7] + x[11] <= 0.0)
@constraint(model, e10, -2.0*x[8] - x[9] + x[12] <= 0.0)

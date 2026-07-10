using JuMP

model = Model()

@variable(model, objvar)
@variable(model, x[2:6])

x2=x[2]; x3=x[3]; x4=x[4]; x5=x[5]; x6=x[6]

# Initial levels from GAMS
set_start_value(x[2], -1.0)
set_start_value(x[3], 2.0)
set_start_value(x[4], 1.0)
set_start_value(x[5], -2.0)
set_start_value(x[6], -2.0)

@constraint(model, -( (x[2]-1)^2 + (x[2]-x[3])^2 + (x[3]-x[4])^3 + (x[4]-x[5])^4 + (x[5]-x[6])^4 ) + objvar == 0)
@constraint(model, x[3]^2 + x[4]^3 + x[2] == 6.24264068711929)
@constraint(model, -x[4]^2 + x[3] + x[5] == 0.82842712474619)
@constraint(model, x[2]*x[6] == 2)

@objective(model, Min, objvar)

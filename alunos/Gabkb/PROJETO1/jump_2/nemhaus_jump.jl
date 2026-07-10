using JuMP

model = Model()

@variable(model, objvar)
@variable(model, x[2:6] >= 0)

x2=x[2]; x3=x[3]; x4=x[4]; x5=x[5]; x6=x[6]

@constraint(model, -(2*x[2]*x[4] + 4*x[2]*x[5] + 3*x[2]*x[6] + 6*x[3]*x[4] + 2*x[3]*x[5] + 3*x[3]*x[6] + 5*x[4]*x[5] + 3*x[4]*x[6] + 3*x[5]*x[6]) + objvar == 0)
@constraint(model, x[2] == 1)
@constraint(model, x[3] == 1)
@constraint(model, x[4] == 1)
@constraint(model, x[5] == 1)
@constraint(model, x[6] == 1)

@objective(model, Min, objvar)

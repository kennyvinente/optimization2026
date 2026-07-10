# ex_1_6_jump.jl
# Converted from GAMS Convert NLP to JuMP

using JuMP

model = Model()

@variable(model, -5.0 <= x1 <= 5.0, start = -3.0)
@variable(model, objvar)

@constraint(model, e1,
    -(x1^6 - 15*x1^4 + 27*x1^2) + objvar == 250.0
)

@objective(model, Min, objvar)

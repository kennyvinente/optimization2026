# ex4_1_5_jump.jl
# Converted from GAMS Convert NLP to JuMP

using JuMP

model = Model()

@variable(model, x1 >= -5.0)
@variable(model, x2 <= 5.0)  # GAMS: Negative Variable x2, then x2.up = 5
@variable(model, objvar)

@constraint(model, e1,
    -(2*x1^2 - 1.05*x1^4 + (1/6)*x1^6 - x1*x2 + x2^2) + objvar == 0.0
)

@objective(model, Min, objvar)

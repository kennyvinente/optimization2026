# ex4_1_1_alt_jump.jl
# Alternative ex4_1_1 block received later; kept separate to avoid overwriting ex4_1_1_jump.jl

using JuMP

model = Model()

@variable(model, -5.0 <= x1 <= 5.0, start = -1.0)
@variable(model, objvar)

@constraint(model, e1,
    -(x1^4 - 3*x1^3 - 1.5*x1^2 + 10*x1) + objvar == 0.0
)

@objective(model, Min, objvar)

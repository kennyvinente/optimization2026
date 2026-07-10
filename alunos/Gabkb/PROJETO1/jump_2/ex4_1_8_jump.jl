# ex_1_8_alt_jump.jl
# Alternative ex_1_8 block received later; kept separate to avoid overwriting ex_1_8_jump.jl

using JuMP

model = Model()

@variable(model, 0.0 <= x1 <= 2.0, start = 0.7175)
@variable(model, 0.0 <= x2 <= 3.0, start = 1.47)
@variable(model, objvar)

@constraint(model, e1,
    -(x2^2 - 7*x2) + 12*x1 + objvar == 0.0
)

@constraint(model, e2,
    -2*x1^4 - x2 == -2.0
)

@objective(model, Min, objvar)

# ex_1_9_alt_jump.jl
# Alternative ex_1_9 block received later; kept separate to avoid overwriting ex_1_9_jump.jl

using JuMP

model = Model()

@variable(model, 0.0 <= x1 <= 3.0, start = 2.3295)
@variable(model, 0.0 <= x2 <= 4.0, start = 3.17846)
@variable(model, objvar)

@constraint(model, e1,
    x1 + x2 + objvar == 0.0
)

@constraint(model, e2,
    8*x1^3 - 2*x1^4 - 8*x1^2 + x2 <= 2.0
)

@constraint(model, e3,
    32*x1^3 - 4*x1^4 - 88*x1^2 + 96*x1 + x2 <= 36.0
)

@objective(model, Min, objvar)

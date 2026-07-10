# least_jump.jl
# Convertido de GAMS Convert para JuMP.
# Modelo criado no objeto global `model`.

using JuMP

model = Model()


@variable(model, objvar)
@variable(model, x[2:4])

const x2 = x[2]
const x3 = x[3]
const x4 = x[4]

set_lower_bound(x4, -5.0)
set_upper_bound(x4,  5.0)

set_start_value(x2, 500.0)
set_start_value(x3, -150.0)
set_start_value(x4, -0.2)

ys = Dict(-5 => 127.0, -3 => 151.0, -1 => 379.0, 5 => 421.0, 3 => 460.0, 1 => 426.0)

@constraint(model,
    -(sum((y - x3 * exp(k * x4) - x2)^2 for (k, y) in ys)) + objvar == 0
)

@objective(model, Min, objvar)

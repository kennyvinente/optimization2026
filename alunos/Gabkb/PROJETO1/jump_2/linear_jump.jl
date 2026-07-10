# linear_jump.jl
# Convertido de GAMS Convert para JuMP.
# Modelo criado no objeto global `model`.

using JuMP

model = Model()


@variable(model, objvar)
@variable(model, x[2:25])

for i in 2:25
    @eval const $(Symbol("x", i)) = x[$i]
end

for i in 2:21
    set_lower_bound(x[i], -100.0)
    set_upper_bound(x[i],  100.0)
end

starts = Dict(
    4 => -92.0,
    5 => -94.0,
    7 => -94.0,
    8 => -96.0,
    9 => -83.0,
    10 => -90.0,
    11 => -93.0,
    18 => -84.0,
    19 => -83.0,
    20 => -92.0,
    22 => 1.0,
    23 => 1.0,
    24 => 1.0,
    25 => 1.0,
)
for (i, v) in starts
    set_start_value(x[i], v)
end

A = [
    (99.0, 85.0, 76.0, 44.0),
    (93.0, 82.0, 78.0, 42.0),
    (99.0, 75.0, 73.0, 42.0),
    (97.0, 74.0, 72.0, 44.0),
    (90.0, 76.0, 73.0, 43.0),
    (96.0, 74.0, 69.0, 46.0),
    (93.0, 73.0, 69.0, 46.0),
    (130.0, 96.0, 80.0, 36.0),
    (118.0, 93.0, 78.0, 36.0),
    (88.0, 70.0, 73.0, 37.0),
    (89.0, 82.0, 71.0, 46.0),
    (93.0, 80.0, 72.0, 45.0),
    (94.0, 77.0, 76.0, 42.0),
    (75.0, 67.0, 76.0, 50.0),
    (84.0, 82.0, 70.0, 48.0),
    (91.0, 76.0, 76.0, 41.0),
    (100.0, 74.0, 78.0, 31.0),
    (98.0, 71.0, 80.0, 29.0),
    (101.0, 70.0, 83.0, 39.0),
    (80.0, 64.0, 79.0, 38.0),
]
for i in 1:20
    rhs, a23, a24, a25 = A[i]
    @constraint(model, x[i+1] + x[22] + a23*x[23] + a24*x[24] + a25*x[25] == rhs)
end

@constraint(model, -sum(abs(x[i]) for i in 2:21) + objvar == 0)
@objective(model, Min, objvar)

# launch_jump.jl
# Convertido de GAMS Convert para JuMP.
# Modelo criado no objeto global `model`.

using JuMP

model = Model()


@variable(model, x[1:38])
@variable(model, objvar)

for i in 1:38
    @eval const $(Symbol("x", i)) = x[$i]
end

# Bounds
set_lower_bound(x1, 1.0)
set_lower_bound(x2, 1.0)
set_lower_bound(x3, 1.0)
set_lower_bound(x4, 5.0)
set_lower_bound(x5, 5.0)
set_lower_bound(x6, 5.0)
set_lower_bound(x7, 50.0)
set_lower_bound(x8, 50.0)
set_lower_bound(x9, 50.0)
set_lower_bound(x10, 2.5); set_upper_bound(x10, 4.0)
set_lower_bound(x14, 125.0); set_upper_bound(x14, 150.0)
set_lower_bound(x15, 75.0);  set_upper_bound(x15, 100.0)
set_lower_bound(x16, 50.0);  set_upper_bound(x16, 70.0)
set_lower_bound(x17, 1.0)
set_lower_bound(x18, 1.0)
set_lower_bound(x19, 1.0)
set_lower_bound(x20, 20.0)
set_lower_bound(x21, 20.0)
set_lower_bound(x22, 20.0)
set_lower_bound(x23, 0.25); set_upper_bound(x23, 0.3)
set_lower_bound(x24, 0.24); set_upper_bound(x24, 0.29)
set_lower_bound(x25, 0.16); set_upper_bound(x25, 0.21)
set_lower_bound(x26, 1.2);  set_upper_bound(x26, 1.4)
set_lower_bound(x27, 0.6);  set_upper_bound(x27, 0.75)
set_lower_bound(x28, 0.7);  set_upper_bound(x28, 0.9)
set_lower_bound(x29, 100.0)
set_lower_bound(x30, 100.0)
set_lower_bound(x31, 100.0)
set_lower_bound(x32, 240.0); set_upper_bound(x32, 290.0)
set_lower_bound(x33, 240.0); set_upper_bound(x33, 290.0)
set_lower_bound(x34, 340.0); set_upper_bound(x34, 375.0)
set_lower_bound(x35, 1000.0)
set_lower_bound(x36, 1000.0)
set_lower_bound(x37, 1000.0)
set_lower_bound(x38, 35000.0); set_upper_bound(x38, 50000.0)

starts = Dict(
    4 => 136.0,
    5 => 47.0,
    6 => 16.0,
    7 => 2176.0,
    8 => 564.0,
    9 => 144.0,
    20 => 746.0,
    21 => 96.0,
    22 => 129.0,
    23 => 0.3,
    24 => 0.29,
    25 => 0.21,
    29 => 155.0,
    30 => 314.0,
    31 => 403.0,
    38 => 38632.0,
)
for (i, v) in starts
    set_start_value(x[i], v)
end

@constraint(model, -x1 + 0.5*x4 == 0)
@constraint(model, -x2 + 0.6*x5 == 0)
@constraint(model, -x3 + 0.7*x6 == 0)
@constraint(model, -x4 - x5 - x6 - x7 - x8 - x9 - x10 + x11 == 20)
@constraint(model, -x5 - x6 - x8 - x9 - x10 + x12 == 20)
@constraint(model, -x6 - x9 - x10 + x13 == 20)
@constraint(model, x17 - 5*x20 == 0)
@constraint(model, x18 - 5*x21 == 0)
@constraint(model, x19 - x22 == 0)
@constraint(model, x26*x11 - x17 == 0)
@constraint(model, x27*x12 - x18 == 0)
@constraint(model, x28*x13 - x19 == 0)
@constraint(model, (1 - x23)*x11 - x7 == 0)
@constraint(model, (1 - x24)*x12 - x8 == 0)
@constraint(model, (1 - x25)*x13 - x9 == 0)
@constraint(model, 12*x4 - x7 <= 0)
@constraint(model, 10*x5 - x8 <= 0)
@constraint(model, 7*x6 - x9 <= 0)
@constraint(model, -16*x4 + x7 <= 0)
@constraint(model, -12*x5 + x8 <= 0)
@constraint(model, -9*x6 + x9 <= 0)
@constraint(model, x32*x7 - x17*x29 == 0)
@constraint(model, x33*x8 - x18*x30 == 0)
@constraint(model, x34*x9 - x19*x31 == 0)
@constraint(model, -31.8*x32*log(1 / x23) + x35 == 0)
@constraint(model, -31.8*x33*log(1 / x24) + x36 == 0)
@constraint(model, -31.8*x34*log(1 / x25) + x37 == 0)
@constraint(model, -x35 - x36 - x37 + x38 == 0)

cost = 5272.77 * (
    x1^1.2781 * x4^(-0.1959) * x23^2.4242 * x17^0.38745 * x7^(-0.9904) +
    x2^1.2781 * x5^(-0.1959) * x24^2.4242 * x18^0.38745 * x8^(-0.9904) +
    x3^1.2781 * x6^(-0.1959) * x25^2.4242 * x19^0.38745 * x9^(-0.9904)
) + 0.185214 * (
    10.3027592771433*x1^0.3322*x23^(-1.5935)*x7^0.2362*x14^0.1079 +
    10.3027592771433*x2^0.3322*x24^(-1.5935)*x8^0.2362*x15^0.1079 +
    7.94328234724281*x3^0.3322*x25^(-1.5935)*x9^0.2362*x16^0.1079
) +
    160.99*(0.001*x20)^(-0.146) + 282.874*(0.001*x20)^0.648 +
    160.99*(0.001*x21)^(-0.146) + 282.874*(0.001*x21)^0.648 +
    181.806*(0.001*x22)^0.539 + 232.57*(0.001*x22)^0.772 +
    38.0226256753606*(2.509*(0.001*x20)^0.736 + 0.0002085*x20 + 0.9744*(0.001*x20)^(-0.229)) +
    38.0226256753606*(2.509*(0.001*x21)^0.736 + 0.0002085*x21 + 0.9744*(0.001*x21)^(-0.229)) +
    8.51138038202377*(7.05e-5*x22 - 0.000845197400305967*(0.001*x22)^(-1.33) + 52.5264761174087*(0.001*x22)^0.498) +
    0.1637577*(1000*x10)^0.786 + 0.125678613298076*(1000*x10)^0.786 +
    85*(0.003*x7 + 0.003*x8 + 0.003*x9)^0.46

@constraint(model, -cost + objvar == -850.76)
@objective(model, Min, objvar)

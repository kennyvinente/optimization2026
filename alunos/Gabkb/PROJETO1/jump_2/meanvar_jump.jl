using JuMP

model = Model()

@variable(model, objvar)
@variable(model, x[2:9])

# Bounds / fixed values from GAMS
fix(x[2], 0.115; force=true)
for i in 3:9
    set_lower_bound(x[i], 0.0)
    set_upper_bound(x[i], 1.0)
end

# Convenient aliases
x2=x[2]; x3=x[3]; x4=x[4]; x5=x[5]; x6=x[6]; x7=x[7]; x8=x[8]; x9=x[9]

# Mean/return constraint
@constraint(model, x[2] - 0.1287*x[3] - 0.1096*x[4] - 0.0501*x[5] - 0.1524*x[6] - 0.0763*x[7] - 0.1854*x[8] - 0.062*x[9] == 0)

# Budget constraint
@constraint(model, sum(x[i] for i in 3:9) == 1)

Q = [
    42.18 20.18 10.88 5.3 12.32 23.84 17.41;
    20.18 70.89 21.58 15.41 23.24 23.8 12.62;
    10.88 21.58 25.51 9.6 22.63 13.22 4.7;
    5.3 15.41 9.6 22.33 10.32 10.46 1.0;
    12.32 23.24 22.63 10.32 30.01 16.36 7.2;
    23.84 23.8 13.22 10.46 16.36 42.23 9.9;
    17.41 12.62 4.7 1.0 7.2 9.9 16.42
]
@expression(model, variance_expr, sum(Q[i,j] * x[i+2] * x[j+2] for i in 1:7, j in 1:7))
@constraint(model, -0.5 * variance_expr + objvar == 0)

@objective(model, Min, objvar)

# Arquivo convertido de GAMS Convert para JuMP
using JuMP


model = Model()

@variable(model, 0 <= x[1:10] <= 1)
@variable(model, objvar)
for i in [1,4,5,6,8,9,10]
    set_start_value(x[i], 1.0)
end

@objective(model, Min, objvar)

c = [48.0, 42.0, 48.0, 45.0, 44.0, 41.0, 47.0, 42.0, 45.0, 46.0]
@constraint(model, e1, -(sum(c[i]*x[i] for i in 1:10) - 0.5*sum(100.0*x[i]^2 for i in 1:10)) + objvar == 0.0)
@constraint(model, e2, -2*x[1] -6*x[2] -x[3] -3*x[5] -3*x[6] -2*x[7] -6*x[8] -2*x[9] -2*x[10] <= -4)
@constraint(model, e3, 6*x[1] -5*x[2] +8*x[3] -3*x[4] +x[6] +3*x[7] +8*x[8] +9*x[9] -3*x[10] <= 22)
@constraint(model, e4, -5*x[1] +6*x[2] +5*x[3] +3*x[4] +8*x[5] -8*x[6] +9*x[7] +2*x[8] -9*x[10] <= -6)
@constraint(model, e5, 9*x[1] +5*x[2] -9*x[4] +x[5] -8*x[6] +3*x[7] -9*x[8] -9*x[9] -3*x[10] <= -23)
@constraint(model, e6, -8*x[1] +7*x[2] -4*x[3] -5*x[4] -9*x[5] +x[6] -7*x[7] -x[8] +3*x[9] -2*x[10] <= -12)

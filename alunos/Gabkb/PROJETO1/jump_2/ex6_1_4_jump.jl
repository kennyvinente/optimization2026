using JuMP
using Ipopt

model = Model(Ipopt.Optimizer)
set_name(model, "ex6_1_4")

@variable(model, objvar)

@variable(model, 1e-6 <= x2 <= 1.0, start = 7e-5)
@variable(model, 1e-6 <= x3 <= 1.0, start = 0.99686)
@variable(model, 1e-6 <= x4 <= 1.0, start = 0.00307)

@variable(model, x5 >= 0, start = 0.000474076675116379)
@variable(model, x6 >= 0, start = 0.997993046160137)
@variable(model, x7 >= 0, start = 0.0126755759820888)

@objective(model, Min, objvar)

@constraint(model, e1,
    -(
        x2 * (0.28809 + log(x2)) +
        x3 * (log(x3) - 0.29158) +
        x4 * (0.59336 + log(x4)) +
        x2 * (1.44805026165593 * x6 + 0.989428667054834 * x7) +
        x3 * (1.12676386427658 * x5 + 1.00363012835441 * x7) +
        x4 * (0.0347225450624344 * x5 + 0.82681418300153 * x6)
    ) + objvar == 0
)

@constraint(model, e2,
    x5 * (x2 + 0.145002897355373 * x3 + 0.989528214945409 * x4) - x2 == 0
)

@constraint(model, e3,
    x6 * (0.293701311601799 * x2 + x3 + 0.646291923054068 * x4) - x3 == 0
)

@constraint(model, e4,
    x7 * (0.619143628558899 * x2 + 0.239837817616513 * x3 + x4) - x4 == 0
)

@constraint(model, e5, x2 + x3 + x4 == 1)

optimize!(model)
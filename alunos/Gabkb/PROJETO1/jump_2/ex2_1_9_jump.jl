# Arquivo convertido de GAMS Convert para JuMP
using JuMP


model = Model()

@variable(model, x[1:10] >= 0)
@variable(model, objvar)
for i in 4:7
    set_start_value(x[i], 0.25)
end

@objective(model, Min, objvar)

pairs = [
    (1,2),(2,3),(3,4),(4,5),(5,6),(6,7),(7,8),(8,9),(9,10),
    (1,3),(2,4),(3,5),(4,6),(5,7),(6,8),(7,9),(8,10),
    (1,9),(1,10),(2,10),(1,5),(4,7)
]
@constraint(model, e1, -sum(x[i]*x[j] for (i,j) in pairs) - objvar == 0.0)
@constraint(model, e2, sum(x) == 1.0)

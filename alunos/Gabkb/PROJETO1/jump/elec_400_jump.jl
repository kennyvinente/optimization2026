using JuMP
using Random

# ============================================================
# elec_400_jump.jl
# Tradução manual do arquivo elec_400.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

np = 400

# Mesmo randseed do AMPL:
# option randseed '861276191';
Random.seed!(861276191)

theta = Dict(i => 2*pi*rand() for i in 1:np)
phi   = Dict(i => pi*rand() for i in 1:np)

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, x[1:np])
@variable(model, y[1:np])
@variable(model, z[1:np])

# ------------------------------------------------------------
# Valores iniciais
# AMPL:
# x[i] := cos(theta[i])*sin(phi[i])
# y[i] := sin(theta[i])*sin(phi[i])
# z[i] := cos(phi[i])
# ------------------------------------------------------------

for i in 1:np
    set_start_value(x[i], cos(theta[i]) * sin(phi[i]))
    set_start_value(y[i], sin(theta[i]) * sin(phi[i]))
    set_start_value(z[i], cos(phi[i]))
end

# ------------------------------------------------------------
# Função objetivo
# Potencial de Coulomb
# ------------------------------------------------------------

@NLobjective(
    model,
    Min,
    sum(
        sum(
            1.0 / sqrt(
                (x[i] - x[j])^2 +
                (y[i] - y[j])^2 +
                (z[i] - z[j])^2
            )
            for j in (i+1):np
        )
        for i in 1:(np-1)
    )
)

# ------------------------------------------------------------
# Restrição: cada elétron fica na esfera unitária
# ------------------------------------------------------------

@NLconstraint(
    model,
    on_the_unit_ball[i in 1:np],
    x[i]^2 + y[i]^2 + z[i]^2 == 1.0
)

println("Modelo elec_400 carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

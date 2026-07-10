using JuMP

# ============================================================
# clnlbeam_jump.jl
# Tradução manual do arquivo clnlbeam.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

ni = 20000
alpha = 350.0
h = 1 / ni

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, -1.0 <= t[0:ni] <= 1.0)
@variable(model, -0.05 <= x[0:ni] <= 0.05)
@variable(model, u[0:ni])

# ------------------------------------------------------------
# Valores iniciais
# AMPL:
# t[i] := 0.05*cos(i*h)
# x[i] := 0.05*cos(i*h)
# ------------------------------------------------------------

for i in 0:ni
    set_start_value(t[i], 0.05 * cos(i*h))
    set_start_value(x[i], 0.05 * cos(i*h))
    set_start_value(u[i], 0.0)
end

# ------------------------------------------------------------
# Condições fixas
# AMPL:
# fix x[0] := 0.0;
# fix x[ni] := 0.0;
# fix t[0] := 0.0;
# fix t[ni] := 0.0;
# ------------------------------------------------------------

fix(x[0], 0.0; force = true)
fix(x[ni], 0.0; force = true)
fix(t[0], 0.0; force = true)
fix(t[ni], 0.0; force = true)

# ------------------------------------------------------------
# Função objetivo
# AMPL:
# minimize f:
#   sum {i in 0..ni-1}
#   0.5*h*(u[i+1]^2 + u[i]^2)
#   + 0.5*alpha*h*(cos(t[i+1]) + cos(t[i]));
# ------------------------------------------------------------

@NLobjective(
    model,
    Min,
    sum(
        0.5*h*(u[i+1]^2 + u[i]^2) +
        0.5*alpha*h*(cos(t[i+1]) + cos(t[i]))
        for i in 0:(ni-1)
    )
)

# ------------------------------------------------------------
# Restrições
# ------------------------------------------------------------

@NLconstraint(
    model,
    cons1[i in 0:(ni-1)],
    x[i+1] - x[i] - 0.5*h*(sin(t[i+1]) + sin(t[i])) == 0
)

@NLconstraint(
    model,
    cons2[i in 0:(ni-1)],
    t[i+1] - t[i] - 0.5*h*u[i+1] - 0.5*h*u[i] == 0
)

println("Modelo clnlbeam carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

model
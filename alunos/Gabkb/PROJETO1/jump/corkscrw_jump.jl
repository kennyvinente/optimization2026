using JuMP

# ============================================================
# corkscrw_jump.jl
# Tradução manual do arquivo corkscrw.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

t = 5000
xt = 10.0
mass = 0.37
tol = 0.1

h = xt / t
w = xt * (t + 1) / 2

fmax = xt / t

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, 0.0 <= x[0:t] <= xt)
@variable(model, y[0:t])
@variable(model, z[0:t])

@variable(model, vx[0:t])
@variable(model, vy[0:t])
@variable(model, vz[0:t])

@variable(model, -fmax <= ux[1:t] <= fmax)
@variable(model, -fmax <= uy[1:t] <= fmax)
@variable(model, -fmax <= uz[1:t] <= fmax)

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

for i in 0:t
    set_start_value(x[i], i*h)
    set_start_value(y[i], sin(i*h))
    set_start_value(z[i], cos(i*h))

    set_start_value(vx[i], 1.0)
    set_start_value(vy[i], 0.0)
    set_start_value(vz[i], 0.0)
end

for i in 1:t
    set_start_value(ux[i], 0.0)
    set_start_value(uy[i], 0.0)
    set_start_value(uz[i], 0.0)
end

# ------------------------------------------------------------
# Variáveis fixadas
# ------------------------------------------------------------

fix(x[0], 0.0; force = true)
fix(y[0], 0.0; force = true)
fix(z[0], 1.0; force = true)

fix(vx[0], 0.0; force = true)
fix(vy[0], 0.0; force = true)
fix(vz[0], 0.0; force = true)

fix(vx[t], 0.0; force = true)
fix(vy[t], 0.0; force = true)
fix(vz[t], 0.0; force = true)

# ------------------------------------------------------------
# Função objetivo
# AMPL:
# minimize f:
#   sum {i in 1..t} (i*h/w)*(x[i] - xt)^2;
# ------------------------------------------------------------

@objective(
    model,
    Min,
    sum((i*h/w) * (x[i] - xt)^2 for i in 1:t)
)

# ------------------------------------------------------------
# Equações de aceleração
# ------------------------------------------------------------

@constraint(
    model,
    acx[i in 1:t],
    mass * (vx[i] - vx[i-1]) / h - ux[i] == 0
)

@constraint(
    model,
    acy[i in 1:t],
    mass * (vy[i] - vy[i-1]) / h - uy[i] == 0
)

@constraint(
    model,
    acz[i in 1:t],
    mass * (vz[i] - vz[i-1]) / h - uz[i] == 0
)

# ------------------------------------------------------------
# Equações de posição
# ------------------------------------------------------------

@constraint(
    model,
    psx[i in 1:t],
    (x[i] - x[i-1]) / h - vx[i] == 0
)

@constraint(
    model,
    psy[i in 1:t],
    (y[i] - y[i-1]) / h - vy[i] == 0
)

@constraint(
    model,
    psz[i in 1:t],
    (z[i] - z[i-1]) / h - vz[i] == 0
)

# ------------------------------------------------------------
# Restrição não linear da trajetória helicoidal
# ------------------------------------------------------------

@NLconstraint(
    model,
    sc[i in 1:t],
    (y[i] - sin(x[i]))^2 + (z[i] - cos(x[i]))^2 - tol^2 <= 0
)

println("Modelo corkscrw carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

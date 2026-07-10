using JuMP

# ============================================================
# cont5_1_l_jump.jl
# Tradução manual do arquivo cont5_1_l.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

n = 300
m = n

n1 = n - 1
m1 = m - 1

T = 1.0
dt = T / m

l = atan(1.0)
dx = l / n
h2 = dx^2

s2 = sqrt(2.0) / 2.0

e1 = exp(1.0) + 1.0 / exp(1.0)
e13 = exp(1.0 / 3.0)
e132 = e13 * (e13 - 1.0)

nu = s2 * e132

yt = Dict(j => e1 * cos(j * dx) for j in 0:n)

# Termo constante usado em bc2
g = Dict(
    i => min(1.0, max(0.0, (exp(i * dt) - e13) / e132))
    for i in 1:m
)

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, -10.0 <= y[0:m, 0:n] <= 10.0)
@variable(model, 0.0 <= u[1:m] <= 1.0)

# ------------------------------------------------------------
# Valores iniciais
# Não havia let explícito no .mod, então usamos valores simples.
# ------------------------------------------------------------

for i in 0:m
    for j in 0:n
        set_start_value(y[i,j], cos(j * dx))
    end
end

for i in 1:m
    set_start_value(u[i], 0.5)
end

# ------------------------------------------------------------
# Função objetivo
# ------------------------------------------------------------

@NLobjective(
    model,
    Min,
    0.25 * dx * (
        (y[m,0] - yt[0])^2 +
        2.0 * sum((y[m,j] - yt[j])^2 for j in 1:n1) +
        (y[m,n] - yt[n])^2
    )
    +
    0.25 * nu * dt * (
        2.0 * sum(u[i]^2 for i in 1:m1) +
        u[m]^2
    )
    +
    dt * (
        sum(
            -exp(-2.0 * i * dt) * y[i,n] + s2 * e13 * u[i]
            for i in 1:m1
        )
        +
        0.5 * (
            -exp(-2.0 * T) * y[m,n] + s2 * e13 * u[m]
        )
    )
)

# ------------------------------------------------------------
# PDE discreta
# ------------------------------------------------------------

@NLconstraint(
    model,
    pde[i in 0:m1, j in 1:n1],
    (y[i+1,j] - y[i,j]) / dt ==
    0.5 * (
        y[i,j-1] - 2.0*y[i,j] + y[i,j+1] +
        y[i+1,j-1] - 2.0*y[i+1,j] + y[i+1,j+1]
    ) / h2
)

# ------------------------------------------------------------
# Condição inicial
# ------------------------------------------------------------

@NLconstraint(
    model,
    ic[j in 0:n],
    y[0,j] == cos(j * dx)
)

# ------------------------------------------------------------
# Condições de contorno
# ------------------------------------------------------------

@NLconstraint(
    model,
    bc1[i in 1:m],
    (y[i,2] - 4.0*y[i,1] + 3.0*y[i,0]) / (2.0 * dx) == 0.0
)

@NLconstraint(
    model,
    bc2[i in 1:m],
    (y[i,n-2] - 4.0*y[i,n1] + 3.0*y[i,n]) / (2.0 * dx) + y[i,n]
    ==
    u[i]
    + 0.25 * exp(-4.0 * i * dt)
    - g[i]
    - y[i,n] * abs(y[i,n])^3
)

println("Modelo cont5_1_l carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))
model
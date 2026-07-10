using JuMP

# ============================================================
# dtoc1nd_jump.jl
# Tradução manual do arquivo dtoc1nd.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

n = 150
nx = 15
ny = 25

mu = 1.0

b = [
    (i - j) / (nx + ny)
    for i in 1:ny, j in 1:nx
]

c = [
    (i + j) * mu / (nx + ny)
    for i in 1:ny, j in 1:nx
]

K = [
    (div(k, nx) + 1, k - nx * div(k, nx) + 1)
    for k in 0:(ny * nx - 1)
]

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, x[1:n-1, 1:nx])
@variable(model, y[1:n, 1:ny])

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

for t in 1:n-1
    for i in 1:nx
        set_start_value(x[t,i], 0.0)
    end
end

for t in 1:n
    for i in 1:ny
        set_start_value(y[t,i], 0.0)
    end
end

# ------------------------------------------------------------
# Fixação da condição inicial
# AMPL:
# fix {i in 1..ny} y[1,i] := 0.0;
# ------------------------------------------------------------

for i in 1:ny
    fix(y[1,i], 0.0; force = true)
end

# ------------------------------------------------------------
# Função objetivo
# ------------------------------------------------------------

@NLobjective(
    model,
    Min,
    sum((x[t,i] + 0.5)^4 for t in 1:n-1, i in 1:nx)
    +
    sum((y[t,i] + 0.25)^4 for t in 1:n, i in 1:ny)
)

# ------------------------------------------------------------
# Restrições
# ------------------------------------------------------------

@NLconstraint(
    model,
    cons1[t in 1:n-1],
    sum(c[r,s] * y[t,r] * x[t,s] for (r,s) in K)
    + 0.5 * y[t,1]
    + 0.25 * y[t,2]
    - y[t+1,1]
    + sum(b[1,i] * x[t,i] for i in 1:nx)
    == 0
)

@NLconstraint(
    model,
    cons2[t in 1:n-1, j in 2:ny-1],
    sum(c[r,s] * y[t,r] * x[t,s] for (r,s) in K)
    - y[t+1,j]
    + 0.5 * y[t,j]
    - 0.25 * y[t,j-1]
    + 0.25 * y[t,j+1]
    + sum(b[j,i] * x[t,i] for i in 1:nx)
    == 0
)

@NLconstraint(
    model,
    cons3[t in 1:n-1],
    sum(c[r,s] * y[t,r] * x[t,s] for (r,s) in K)
    + 0.5 * y[t,ny]
    - 0.25 * y[t,ny-1]
    - y[t+1,ny]
    + sum(b[ny,i] * x[t,i] for i in 1:nx)
    == 0
)

println("Modelo dtoc1nd carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

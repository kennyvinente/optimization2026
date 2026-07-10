using JuMP

# ============================================================
# dtoc2_jump.jl
# Tradução manual do arquivo dtoc2.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

n = 1300
nx = 20
ny = 30

c = [
    (i + j) / (2 * ny)
    for i in 1:ny, j in 1:nx
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
    for j in 1:ny
        set_start_value(y[t,j], 0.0)
    end
end

# ------------------------------------------------------------
# Fixação da condição inicial
# AMPL:
# fix{i in 1..ny} y[1,i] := i/(2*ny);
# ------------------------------------------------------------

for i in 1:ny
    fix(y[1,i], i / (2 * ny); force = true)
end

# ------------------------------------------------------------
# Função objetivo
# ------------------------------------------------------------

@NLobjective(
    model,
    Min,
    sum(
        (
            sum(y[t,j]^2 for j in 1:ny)
        )
        *
        (
            sin(0.5 * sum(x[t,j]^2 for j in 1:nx))^2 + 1.0
        )
        for t in 1:n-1
    )
    +
    sum(y[n,j]^2 for j in 1:ny)
)

# ------------------------------------------------------------
# Restrições
# ------------------------------------------------------------

@NLconstraint(
    model,
    cons1[t in 1:n-1, j in 1:ny],
    sin(y[t,j])
    + sum(c[j,i] * sin(x[t,i]) for i in 1:nx)
    - y[t+1,j]
    == 0
)

println("Modelo dtoc2 carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

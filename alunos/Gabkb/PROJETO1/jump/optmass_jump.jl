using JuMP

# ============================================================
# optmass_jump.jl
# Tradução manual do arquivo optmass.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

n = 10000

speed = 0.01
pen = 0.335

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, x[1:2, 0:n+1])
@variable(model, v[1:2, 0:n+1])
@variable(model, f[1:2, 0:n])

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

for j in 1:2
    for i in 0:n+1
        set_start_value(x[j,i], 0.0)
        set_start_value(v[j,i], 0.0)
    end
end

for j in 1:2
    for i in 0:n
        set_start_value(f[j,i], 0.0)
    end
end

# ------------------------------------------------------------
# Fixações
# ------------------------------------------------------------

fix(x[1,0], 0.0; force = true)
fix(x[2,0], 0.0; force = true)

fix(v[1,0], speed; force = true)
fix(v[2,0], 0.0; force = true)

# ------------------------------------------------------------
# Objetivo
# ------------------------------------------------------------

@NLobjective(
    model,
    Min,
    pen * (v[1,n+1]^2 + v[2,n+1]^2)
    -
    (x[1,n+1]^2 + x[2,n+1]^2)
)

# ------------------------------------------------------------
# Restrições
# ------------------------------------------------------------

@NLconstraint(
    model,
    cons1[i in 1:n+1, j in 1:2],
    x[j,i] - x[j,i-1] - v[j,i-1]/n - f[j,i-1]/(2*n^2) == 0
)

@NLconstraint(
    model,
    cons2[i in 1:n+1, j in 1:2],
    v[j,i] - v[j,i-1] - f[j,i-1]/n == 0
)

@NLconstraint(
    model,
    cons3[i in 0:n],
    f[1,i]^2 + f[2,i]^2 <= 1
)

println("Modelo optmass carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

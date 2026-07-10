using JuMP

# ============================================================
# ex4_2_160_jump.jl
# Tradução manual do arquivo ex4_2_160.mod para JuMP
# ============================================================

model = Model()
set_string_names_on_creation(model, false)

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

n = 159
n1 = n + 1

b = 1.0
ub = 7.1
r = 1.7
d = 2.0
sk = 0.0
sm = 1.0

h = 1.0 / n1
h2 = h^2

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, 0.0 <= u[0:n1, 0:n1] <= ub)
@variable(model, r <= f[1:n, 1:n] <= d)

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

for i in 0:n1
    for j in 0:n1
        set_start_value(u[i,j], 6.0)
    end
end

for i in 1:n
    for j in 1:n
        set_start_value(f[i,j], 2.0)
    end
end

# ------------------------------------------------------------
# Parâmetro a[i,j]
# AMPL:
# a[i,j] = 7 + 4*sin(2*pi*i*j*h2)
# ------------------------------------------------------------

aij(i,j) = 7.0 + 4.0*sin(2.0*pi*i*j*h2)

# ------------------------------------------------------------
# Função objetivo
# ------------------------------------------------------------

@NLobjective(
    model,
    Min,
    h2 * sum(
        f[i,j] * (sm*f[i,j] - sk*u[i,j])
        for i in 1:n, j in 1:n
    )
)

# ------------------------------------------------------------
# PDE discreta
# ------------------------------------------------------------

@NLconstraint(
    model,
    pde[i in 1:n, j in 1:n],
    4.0*u[i,j]
    -
    (
        u[i-1,j] + u[i+1,j] +
        u[i,j-1] + u[i,j+1]
    )
    -
    u[i,j] * (aij(i,j) - f[i,j] - b*u[i,j]) * h2
    == 0.0
)

# ------------------------------------------------------------
# Condições de contorno
# ------------------------------------------------------------

@constraint(model, bc1[i in 1:n], u[i,0] == u[i,1])
@constraint(model, bc2[j in 1:n], u[0,j] == u[1,j])
@constraint(model, bc3[i in 1:n], u[i,n1] == u[i,n])
@constraint(model, bc4[j in 1:n], u[n1,j] == u[n,j])

println("Modelo ex4_2_160 carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

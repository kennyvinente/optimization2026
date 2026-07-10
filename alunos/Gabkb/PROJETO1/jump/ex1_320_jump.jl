using JuMP

# ============================================================
# ex1_320_jump.jl
# Tradução manual do arquivo ex1_320.mod para JuMP
# ============================================================

model = Model()
set_string_names_on_creation(model, false)

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

n = 319
h = 1.0 / (n + 1)
h2 = h^2
n2 = n^2
a = 0.001

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, 0.0 <= x[1:n2] <= 0.185)
@variable(model, 1.5 <= u[1:n2] <= 4.5)

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

for k in 1:n2
    set_start_value(x[k], 0.1)
    set_start_value(u[k], 3.0)
end

# ------------------------------------------------------------
# Função z[i,j]
# AMPL:
# z[i,j] = 1 + 2*(i*h*(i*h-1) + j*h*(j*h-1))
# ------------------------------------------------------------

z(i,j) = 1.0 + 2.0 * (i*h*(i*h - 1.0) + j*h*(j*h - 1.0))

# ------------------------------------------------------------
# Função objetivo
# ------------------------------------------------------------

@NLobjective(
    model,
    Min,
    0.5*h2*sum(
        (x[(i-1)*n + j] - z(i,j))^2
        for i in 1:n, j in 1:n
    )
    +
    0.5*a*h2*sum(
        u[(i-1)*n + j]^2
        for i in 1:n, j in 1:n
    )
)

# ------------------------------------------------------------
# PDE discreta
#
# Equivalente a:
# sum{(i,j) in P} A[i,j]*x[j]
#
# Usando diretamente a estrutura de 5 pontos:
# 4*x[k] - vizinhos
# ------------------------------------------------------------

for row in 1:n
    for col in 1:n
        k = (row - 1) * n + col

        vizinhos = 0.0

        if row > 1
            vizinhos += x[(row - 2) * n + col]
        end

        if row < n
            vizinhos += x[row * n + col]
        end

        if col > 1
            vizinhos += x[(row - 1) * n + col - 1]
        end

        if col < n
            vizinhos += x[(row - 1) * n + col + 1]
        end

        @constraint(
            model,
            4.0 * x[k]
            - vizinhos
            - h2 * (x[k] - x[k]^3 + u[k])
            == 0.0
        )
    end
end

println("Modelo ex1_320 carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

using JuMP

# ============================================================
# svanberg_jump.jl
# Tradução corrigida do arquivo svanberg.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

n = 50000

b = [
    i * 5.0 / n + 10.0
    for i in 1:n
]

a = [
    isodd(i) ? (i * 2.0 / n + 1.0) : (5.0 - i * 3.0 / n)
    for i in 1:n
]

# ------------------------------------------------------------
# Função auxiliar para índice periódico
# ------------------------------------------------------------
# Garante que os índices fiquem sempre entre 1 e n.
#
# Exemplos:
# periodic_index(0, n)     retorna n
# periodic_index(n + 1, n) retorna 1
# ------------------------------------------------------------

periodic_index(i, n) = mod(i - 1, n) + 1

# ------------------------------------------------------------
# Padrão das restrições
# ------------------------------------------------------------
# Cada restrição usa:
#
# i-4, i-3, i-2, i-1, i, i+1, i+2, i+3, i+4
#
# Para i par:
#
# 1/(1 - x[i-4])
# 1/(1 + x[i-3])
# 1/(1 + x[i-2])
# 1/(1 - x[i-1])
# 1/(1 + x[i])
# 1/(1 + x[i+1])
# 1/(1 - x[i+2])
# 1/(1 + x[i+3])
# 1/(1 - x[i+4])
#
# Para i ímpar, os sinais são invertidos.
# ------------------------------------------------------------

offsets = [-4, -3, -2, -1, 0, 1, 2, 3, 4]

sign_even = [-1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0, -1.0]

IDX = Array{Int}(undef, n, 9)
SGN = Array{Float64}(undef, n, 9)

for i in 1:n
    for p in 1:9
        IDX[i, p] = periodic_index(i + offsets[p], n)

        if iseven(i)
            SGN[i, p] = sign_even[p]
        else
            SGN[i, p] = -sign_even[p]
        end
    end
end

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, -0.8 <= x[1:n] <= 0.8)

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

for i in 1:n
    set_start_value(x[i], 0.0)
end

# ------------------------------------------------------------
# Função objetivo
# ------------------------------------------------------------

@NLobjective(
    model,
    Min,
    sum(a[i] / (1.0 + x[i]) for i in 1:2:n-1)
    +
    sum(a[i] / (1.0 - x[i]) for i in 2:2:n)
)

# ------------------------------------------------------------
# Restrições principais
# ------------------------------------------------------------
# Esta formulação substitui cons1, cons2, ..., cons10.
# Ela também trata automaticamente as restrições de borda.
# ------------------------------------------------------------

@NLconstraint(
    model,
    cons[i in 1:n],
    sum(
        1.0 / (1.0 + SGN[i, p] * x[IDX[i, p]])
        for p in 1:9
    ) <= b[i]
)

# ------------------------------------------------------------
# Informações para diagnóstico
# ------------------------------------------------------------

println("Modelo svanberg carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições totais: ", num_constraints(model; count_variable_in_set_constraints = true))
println("Restrições sem bounds: ", num_constraints(model; count_variable_in_set_constraints = false))

# ------------------------------------------------------------
# Para resolver manualmente
# ------------------------------------------------------------
#
# using Ipopt
#
# set_optimizer(model, Ipopt.Optimizer)
# set_optimizer_attribute(model, "print_level", 5)
# set_optimizer_attribute(model, "max_iter", 3000)
# set_optimizer_attribute(model, "tol", 1e-7)
#
# optimize!(model)
#
# println("Status: ", termination_status(model))
# println("Status primal: ", primal_status(model))
#
# if has_values(model)
#     println("Objetivo: ", objective_value(model))
# end
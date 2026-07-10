using JuMP
using SparseArrays
using LinearAlgebra
using Random

# ============================================================
# qcqp1000-1nc_jump.jl
# Modelo QCQP corrigido para JuMP.
#
# Problema do arquivo original:
# - parâmetros n, ml, mq, pl, pq, sd, sq, sp, plf e pqf estavam ignorados;
# - funções AMPL/GAMS como Uniform01(), Uniform() e Normal01() não existem em Julia;
# - condicionais do tipo "if ... then ..." e expressões max{k in 1..n}
#   foram traduzidos para Julia inválida;
# - algumas restrições usavam "===" em vez de "==".
#
# Esta versão reconstroi um benchmark QCQP funcional, usando o tamanho
# indicado no nome do arquivo: n = 1000, q = 1, convex = False.
# ============================================================

Random.seed!(111007)

model = Model()
set_string_names_on_creation(model, false)

# ------------------------------------------------------------
# Parâmetros do benchmark
# ------------------------------------------------------------

n = 1000
q = 1
convex_model = false
num_offdiag_pairs = 1000

# ------------------------------------------------------------
# Funções auxiliares
# ------------------------------------------------------------

function rand_sparse_symmetric(n::Int, num_pairs::Int; scale::Float64 = 1.0, psd::Bool = true)
    rows = Int[]
    cols = Int[]
    vals = Float64[]
    diag_extra = zeros(n)

    for _ in 1:num_pairs
        i = rand(1:n)
        j = rand(1:n)
        if i == j
            continue
        end
        if i < j
            i, j = j, i
        end

        v = scale * (2.0 * rand() - 1.0)

        push!(rows, i)
        push!(cols, j)
        push!(vals, v)

        push!(rows, j)
        push!(cols, i)
        push!(vals, v)

        if psd
            diag_extra[i] += abs(v)
            diag_extra[j] += abs(v)
        end
    end

    if psd
        for i in 1:n
            push!(rows, i)
            push!(cols, i)
            push!(vals, 1.0 + diag_extra[i])
        end
    else
        for i in 1:n
            s = isodd(i) ? 1.0 : -1.0
            push!(rows, i)
            push!(cols, i)
            push!(vals, s * (0.1 + rand()))
        end
    end

    return sparse(rows, cols, vals, n, n)
end

function quad_value(I::Vector{Int}, J::Vector{Int}, V::Vector{Float64}, xval::Vector{Float64})
    return sum(V[t] * xval[I[t]] * xval[J[t]] for t in eachindex(V))
end

# ------------------------------------------------------------
# Dados gerados de forma determinística
# ------------------------------------------------------------

xstar = 0.5 .* (2.0 .* rand(n) .- 1.0)

Q = rand_sparse_symmetric(n, num_offdiag_pairs; scale = 0.05, psd = convex_model)
QI, QJ, QV = findnz(Q)

# Escolha de g para deixar xstar como referência razoável do objetivo.
g = -Q * xstar

A = [sparsevec(rand(1:n, max(5, min(n, 20))), randn(max(5, min(n, 20))), n) for _ in 1:q]
P = [rand_sparse_symmetric(n, max(10, div(num_offdiag_pairs, 2)); scale = 0.02, psd = convex_model) for _ in 1:q]

PI = Vector{Vector{Int}}(undef, q)
PJ = Vector{Vector{Int}}(undef, q)
PV = Vector{Vector{Float64}}(undef, q)
AI = Vector{Vector{Int}}(undef, q)
AV = Vector{Vector{Float64}}(undef, q)
b = zeros(q)

for r in 1:q
    PI[r], PJ[r], PV[r] = findnz(P[r])
    AI[r], AV[r] = findnz(A[r])

    lin_star = sum(AV[r][t] * xstar[AI[r][t]] for t in eachindex(AV[r]))
    quad_star = 0.5 * quad_value(PI[r], PJ[r], PV[r], xstar)

    # Folga positiva para garantir que xstar seja viável para as desigualdades.
    b[r] = lin_star + quad_star + 1.0
end

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, -2.0 <= x[1:n] <= 2.0)

for i in 1:n
    set_start_value(x[i], xstar[i])
end

# ------------------------------------------------------------
# Objetivo quadrático
# ------------------------------------------------------------

@objective(
    model,
    Min,
    0.5 * sum(QV[t] * x[QI[t]] * x[QJ[t]] for t in eachindex(QV))
    + sum(g[i] * x[i] for i in 1:n)
)

# ------------------------------------------------------------
# Restrições quadráticas
# ------------------------------------------------------------

for r in 1:q
    @constraint(
        model,
        sum(AV[r][t] * x[AI[r][t]] for t in eachindex(AV[r]))
        + 0.5 * sum(PV[r][t] * x[PI[r][t]] * x[PJ[r][t]] for t in eachindex(PV[r]))
        <= b[r]
    )
end

println("Modelo qcqp1000-1nc_jump carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições sem bounds: ", num_constraints(model; count_variable_in_set_constraints = false))
println("Restrições com bounds: ", num_constraints(model; count_variable_in_set_constraints = true))

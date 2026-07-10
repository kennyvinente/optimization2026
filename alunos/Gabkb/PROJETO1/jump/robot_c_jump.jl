using JuMP
using SparseArrays

# ============================================================
# MODELO JuMP CORRIGIDO
# ============================================================
#
# ATENÇÃO:
# Os parâmetros abaixo foram ignorados pelo conversor automático.
# Substitua pelos valores reais do benchmark original.
#
# ============================================================

N = 100
M = 100

C11 = 1.0
C12 = 1.0
C13 = 1.0

C21 = 1.0
C22 = 1.0
C23 = 1.0

C31 = 1.0
C32 = 1.0
C33 = 1.0

if N < 4
    error("N deve ser maior ou igual a 4.")
end

if M < 2
    error("M deve ser maior ou igual a 2.")
end

# ============================================================
# CRIAÇÃO DO MODELO
# ============================================================

model = Model()

# ============================================================
# PARÂMETROS CALCULADOS
# ============================================================

NH = 0
NG = M * 18
H = 1.0 / (N - 1)

# ============================================================
# FUNÇÕES AUXILIARES
# ============================================================

function calcula_BB(i, N, H)
    if i == 1
        return 0.5 * H
    elseif i == 2
        return 23.0 * H / 24.0
    elseif i == N
        return 0.5 * H
    elseif i == N - 1
        return 23.0 * H / 24.0
    else
        return H
    end
end

function calcula_VI(j, i, TP, K, H)
    k = K[j]
    tp = TP[j]

    if i <= k - 2
        return 0.0
    elseif i >= k + 3
        return 0.0
    end

    r = k - i + 3
    a = tp - (k - 1) * H
    b = k * H - tp

    if r == 1
        return a^3 / (6.0 * H^3)
    elseif r == 2
        return 1.0 / 6.0 + 0.5 * a / H + 0.5 * a^2 / H^2 - 0.5 * a^3 / H^3
    elseif r == 3
        return 1.0 / 6.0 + 0.5 * b / H + 0.5 * b^2 / H^2 - 0.5 * b^3 / H^3
    elseif r == 4
        return b^3 / (6.0 * H^3)
    else
        return 0.0
    end
end

function calcula_VI1(j, i, TP, K, H)
    k = K[j]
    tp = TP[j]

    if i <= k - 2
        return 0.0
    elseif i >= k + 3
        return 0.0
    end

    r = k - i + 3
    a = tp - (k - 1) * H
    b = k * H - tp

    if r == 1
        return a^2 / (2.0 * H^3)
    elseif r == 2
        return 0.5 / H + a / H^2 - 1.5 * a^2 / H^3
    elseif r == 3
        return -0.5 / H - b / H^2 + 1.5 * b^2 / H^3
    elseif r == 4
        return -b^2 / (2.0 * H^3)
    else
        return 0.0
    end
end

function calcula_VI2(j, i, TP, K, H)
    k = K[j]
    tp = TP[j]

    if i <= k - 2
        return 0.0
    elseif i >= k + 3
        return 0.0
    end

    r = k - i + 3
    a = tp - (k - 1) * H
    b = k * H - tp

    if r == 1
        return a / H^3
    elseif r == 2
        return 1.0 / H^2 - 3.0 * a / H^3
    elseif r == 3
        return 1.0 / H^2 - 3.0 * b / H^3
    elseif r == 4
        return b / H^3
    else
        return 0.0
    end
end

# ============================================================
# PARÂMETROS INDEXADOS
# ============================================================

TP = [(j - 1.0) / (M - 1.0) for j in 1:M]

K = [
    round(Int, TP[j] / H + 1.0e-6 + 1.0)
    for j in 1:M
]

BB = [
    calcula_BB(i, N, H)
    for i in 1:N
]

VI = [
    calcula_VI(j, i, TP, K, H)
    for j in 1:M, i in 1:N
]

VI1 = [
    calcula_VI1(j, i, TP, K, H)
    for j in 1:M, i in 1:N
]

VI2 = [
    calcula_VI2(j, i, TP, K, H)
    for j in 1:M, i in 1:N
]

V11 = [
    1.5 * 30.0 * TP[i]^2 * ((TP[i] - 2.0) * TP[i] + 1.0)
    for i in 1:M
]

V12 = [
    1.5 * 60.0 * TP[i] * ((2.0 * TP[i] - 3.0) * TP[i] + 1.0)
    for i in 1:M
]

V13 = [
    1.5 * ((360.0 * TP[i] - 360.0) * TP[i] + 60.0)
    for i in 1:M
]

V21 = [
    -0.5 *
    cos(4.7 * TP[i]^3 * ((6.0 * TP[i] - 15.0) * TP[i] + 10.0)) *
    4.7 * 30.0 * TP[i]^2 * ((TP[i] - 2.0) * TP[i] + 1.0)
    for i in 1:M
]

V22 = [
    -0.5 * (
        -sin(4.7 * TP[i]^3 * ((6.0 * TP[i] - 15.0) * TP[i] + 10.0)) *
        (4.7 * 30.0 * TP[i]^2 * ((TP[i] - 2.0) * TP[i] + 1.0))^2
        +
        cos(4.7 * TP[i]^3 * ((6.0 * TP[i] - 15.0) * TP[i] + 10.0)) *
        4.7 * 60.0 * TP[i] * ((2.0 * TP[i] - 3.0) * TP[i] + 1.0)
    )
    for i in 1:M
]

V23 = [
    -0.5 * (
        -cos(4.7 * TP[i]^3 * ((6.0 * TP[i] - 15.0) * TP[i] + 10.0)) *
        (4.7 * 30.0 * TP[i]^2 * ((TP[i] - 2.0) * TP[i] + 1.0))^3
        -
        sin(4.7 * TP[i]^3 * ((6.0 * TP[i] - 15.0) * TP[i] + 10.0)) *
        3.0 * 4.7^2 *
        30.0 * TP[i]^2 * ((TP[i] - 2.0) * TP[i] + 1.0) *
        60.0 * TP[i] * ((2.0 * TP[i] - 3.0) * TP[i] + 1.0)
        +
        cos(4.7 * TP[i]^3 * ((6.0 * TP[i] - 15.0) * TP[i] + 10.0)) *
        ((360.0 * TP[i] - 360.0) * TP[i] + 60.0) *
        4.7
    )
    for i in 1:M
]

V31 = [
    -1.3 * 30.0 * TP[i]^2 * ((TP[i] - 2.0) * TP[i] + 1.0)
    for i in 1:M
]

V32 = [
    -1.3 * 60.0 * TP[i] * ((2.0 * TP[i] - 3.0) * TP[i] + 1.0)
    for i in 1:M
]

V33 = [
    -1.3 * ((360.0 * TP[i] - 360.0) * TP[i] + 60.0)
    for i in 1:M
]

# ============================================================
# VARIÁVEIS
# ============================================================

@variable(model, X[1:N])
@variable(model, SUM[1:M])
@variable(model, SUM1[1:M])
@variable(model, SUM2[1:M])

# ============================================================
# RESTRIÇÕES DE LIGAÇÃO
# ============================================================
#
# Essas restrições estavam faltando no código convertido.
# Elas fazem SUM, SUM1 e SUM2 dependerem de X.
#
# Sem isso, o modelo fica solto, porque o objetivo depende de X,
# mas as restrições dependem apenas de SUM, SUM1 e SUM2.
#
# ============================================================

@constraint(model, [j in 1:M],
    SUM[j] == sum(VI[j, i] * X[i] for i in 1:N)
)

@constraint(model, [j in 1:M],
    SUM1[j] == sum(VI1[j, i] * X[i] for i in 1:N)
)

@constraint(model, [j in 1:M],
    SUM2[j] == sum(VI2[j, i] * X[i] for i in 1:N)
)

# ============================================================
# VALORES INICIAIS
# ============================================================

for i in 1:N
    set_start_value(X[i], 1.0)
end

for j in 1:M
    set_start_value(SUM[j], sum(VI[j, i] for i in 1:N))
    set_start_value(SUM1[j], sum(VI1[j, i] for i in 1:N))
    set_start_value(SUM2[j], sum(VI2[j, i] for i in 1:N))
end

# ============================================================
# OBJETIVO
# ============================================================
#
# O objetivo é linear, então não precisa usar @NLobjective.
#
# ============================================================

@objective(model, Min,
    sum(BB[i] * X[i] for i in 1:N)
)

# ============================================================
# RESTRIÇÕES NÃO LINEARES
# ============================================================

for i in 1:M

    # Grupo 1

    @NLconstraint(model,
        C11 * SUM[i] - V11[i] >= 0
    )

    @NLconstraint(model,
        C11 * SUM[i] + V11[i] >= 0
    )

    @NLconstraint(model,
        C12 * SUM[i]^3 -
        (
            V12[i] * SUM[i]
            - V11[i] * SUM1[i]
        ) >= 0
    )

    @NLconstraint(model,
        C12 * SUM[i]^3 +
        (
            V12[i] * SUM[i]
            - V11[i] * SUM1[i]
        ) >= 0
    )

    @NLconstraint(model,
        C13 * SUM[i]^5 -
        (
            V13[i] * SUM[i]^2
            - 3.0 * V12[i] * SUM[i] * SUM1[i]
            + 3.0 * V11[i] * SUM1[i]^2
            + V11[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    @NLconstraint(model,
        C13 * SUM[i]^5 +
        (
            V13[i] * SUM[i]^2
            - 3.0 * V12[i] * SUM[i] * SUM1[i]
            + 3.0 * V11[i] * SUM1[i]^2
            + V11[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    # Grupo 2

    @NLconstraint(model,
        C21 * SUM[i] - V21[i] >= 0
    )

    @NLconstraint(model,
        C21 * SUM[i] + V21[i] >= 0
    )

    @NLconstraint(model,
        C22 * SUM[i]^3 -
        (
            V22[i] * SUM[i]
            - V21[i] * SUM1[i]
        ) >= 0
    )

    @NLconstraint(model,
        C22 * SUM[i]^3 +
        (
            V22[i] * SUM[i]
            - V21[i] * SUM1[i]
        ) >= 0
    )

    @NLconstraint(model,
        C23 * SUM[i]^5 -
        (
            V23[i] * SUM[i]^2
            - 3.0 * V22[i] * SUM[i] * SUM1[i]
            + 3.0 * V21[i] * SUM1[i]^2
            + V21[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    @NLconstraint(model,
        C23 * SUM[i]^5 +
        (
            V23[i] * SUM[i]^2
            - 3.0 * V22[i] * SUM[i] * SUM1[i]
            + 3.0 * V21[i] * SUM1[i]^2
            + V21[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    # Grupo 3

    @NLconstraint(model,
        C31 * SUM[i] - V31[i] >= 0
    )

    @NLconstraint(model,
        C31 * SUM[i] + V31[i] >= 0
    )

    @NLconstraint(model,
        C32 * SUM[i]^3 -
        (
            V32[i] * SUM[i]
            - V31[i] * SUM1[i]
        ) >= 0
    )

    @NLconstraint(model,
        C32 * SUM[i]^3 +
        (
            V32[i] * SUM[i]
            - V31[i] * SUM1[i]
        ) >= 0
    )

    @NLconstraint(model,
        C33 * SUM[i]^5 -
        (
            V33[i] * SUM[i]^2
            - 3.0 * V32[i] * SUM[i] * SUM1[i]
            + 3.0 * V31[i] * SUM1[i]^2
            + V31[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    @NLconstraint(model,
        C33 * SUM[i]^5 +
        (
            V33[i] * SUM[i]^2
            - 3.0 * V32[i] * SUM[i] * SUM1[i]
            + 3.0 * V31[i] * SUM1[i]^2
            + V31[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

end

# ============================================================
# PARA RESOLVER
# ============================================================
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
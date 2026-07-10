using JuMP
using SparseArrays
# ============================================================
# Modelo JuMP reescrito
# ============================================================
#
# Observação:
# Os valores de N, M, C11, C12, ..., C33 precisam vir do
# arquivo .mod, .dat ou da definição original do benchmark.
#
# Este código corrige:
# 1. Sintaxe inválida if ... then
# 2. Parâmetros não definidos
# 3. K como índice inteiro
# 4. Ligação de S, S1 e S2 com X
# 5. Objetivo linear escrito com @objective
#
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


function build_model(;
    N::Int,
    M::Int,
    C11::Real,
    C12::Real,
    C13::Real,
    C21::Real,
    C22::Real,
    C23::Real,
    C31::Real,
    C32::Real,
    C33::Real,
    optimizer = nothing
)

    if N <= 2
        error("N precisa ser maior que 2.")
    end

    if M <= 1
        error("M precisa ser maior que 1.")
    end

    model = optimizer === nothing ? Model() : Model(optimizer)

    # --------------------------------------------------------
    # Parâmetros calculados
    # --------------------------------------------------------

    NH = 0
    NG = M * 18
    H = 1.0 / (N - 1)

    # --------------------------------------------------------
    # Malha de pontos
    # --------------------------------------------------------

    TP = [(j - 1.0) / (M - 1.0) for j in 1:M]

    K = [
        round(Int, TP[j] / H + 1.0e-6 + 1.0)
        for j in 1:M
    ]

    BB = [
        calcula_BB(i, N, H)
        for i in 1:N
    ]

    # --------------------------------------------------------
    # Matrizes VI, VI1 e VI2
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # Vetores V11, V12, ..., V33
    # --------------------------------------------------------

    V11 = [
        1.5 * 30.0 * TP[j]^2 * ((TP[j] - 2.0) * TP[j] + 1.0)
        for j in 1:M
    ]

    V12 = [
        1.5 * 60.0 * TP[j] * ((2.0 * TP[j] - 3.0) * TP[j] + 1.0)
        for j in 1:M
    ]

    V13 = [
        1.5 * ((360.0 * TP[j] - 360.0) * TP[j] + 60.0)
        for j in 1:M
    ]

    V21 = [
        -0.5 *
        cos(4.7 * TP[j]^3 * ((6.0 * TP[j] - 15.0) * TP[j] + 10.0)) *
        4.7 * 30.0 * TP[j]^2 * ((TP[j] - 2.0) * TP[j] + 1.0)
        for j in 1:M
    ]

    V22 = [
        -0.5 * (
            -sin(4.7 * TP[j]^3 * ((6.0 * TP[j] - 15.0) * TP[j] + 10.0)) *
            (4.7 * 30.0 * TP[j]^2 * ((TP[j] - 2.0) * TP[j] + 1.0))^2
            +
            cos(4.7 * TP[j]^3 * ((6.0 * TP[j] - 15.0) * TP[j] + 10.0)) *
            4.7 * 60.0 * TP[j] * ((2.0 * TP[j] - 3.0) * TP[j] + 1.0)
        )
        for j in 1:M
    ]

    V23 = [
        -0.5 * (
            -cos(4.7 * TP[j]^3 * ((6.0 * TP[j] - 15.0) * TP[j] + 10.0)) *
            (4.7 * 30.0 * TP[j]^2 * ((TP[j] - 2.0) * TP[j] + 1.0))^3
            -
            sin(4.7 * TP[j]^3 * ((6.0 * TP[j] - 15.0) * TP[j] + 10.0)) *
            3.0 * 4.7^2 *
            30.0 * TP[j]^2 * ((TP[j] - 2.0) * TP[j] + 1.0) *
            60.0 * TP[j] * ((2.0 * TP[j] - 3.0) * TP[j] + 1.0)
            +
            cos(4.7 * TP[j]^3 * ((6.0 * TP[j] - 15.0) * TP[j] + 10.0)) *
            ((360.0 * TP[j] - 360.0) * TP[j] + 60.0) *
            4.7
        )
        for j in 1:M
    ]

    V31 = [
        -1.3 * 30.0 * TP[j]^2 * ((TP[j] - 2.0) * TP[j] + 1.0)
        for j in 1:M
    ]

    V32 = [
        -1.3 * 60.0 * TP[j] * ((2.0 * TP[j] - 3.0) * TP[j] + 1.0)
        for j in 1:M
    ]

    V33 = [
        -1.3 * ((360.0 * TP[j] - 360.0) * TP[j] + 60.0)
        for j in 1:M
    ]

    # --------------------------------------------------------
    # Variáveis
    # --------------------------------------------------------

    @variable(model, X[1:N])

    @variable(model, S[1:M])
    @variable(model, S1[1:M])
    @variable(model, S2[1:M])

    # --------------------------------------------------------
    # Ligação entre S, S1, S2 e X
    # --------------------------------------------------------
    #
    # Essas restrições estavam faltando no código original.
    # Sem elas, o modelo fica matematicamente solto.
    #

    @constraint(model, [j in 1:M],
        S[j] == sum(VI[j, i] * X[i] for i in 1:N)
    )

    @constraint(model, [j in 1:M],
        S1[j] == sum(VI1[j, i] * X[i] for i in 1:N)
    )

    @constraint(model, [j in 1:M],
        S2[j] == sum(VI2[j, i] * X[i] for i in 1:N)
    )

    # --------------------------------------------------------
    # Objetivo
    # --------------------------------------------------------

    @objective(model, Min,
        sum(BB[i] * X[i] for i in 1:N)
    )

    # --------------------------------------------------------
    # Restrições não lineares
    # --------------------------------------------------------

    @NLconstraint(model, gx1[j in 1:M],
        C11 * S[j] - V11[j] >= 0
    )

    @NLconstraint(model, gx2[j in 1:M],
        C11 * S[j] + V11[j] >= 0
    )

    @NLconstraint(model, gx3[j in 1:M],
        C12 * S[j]^3 - (V12[j] * S[j] - V11[j] * S1[j]) >= 0
    )

    @NLconstraint(model, gx4[j in 1:M],
        C12 * S[j]^3 + (V12[j] * S[j] - V11[j] * S1[j]) >= 0
    )

    @NLconstraint(model, gx5[j in 1:M],
        C13 * S[j]^5 -
        (
            V13[j] * S[j]^2
            - 3.0 * V12[j] * S[j] * S1[j]
            + 3.0 * V11[j] * S1[j]^2
            + V11[j] * S[j] * S2[j]
        ) >= 0
    )

    @NLconstraint(model, gx6[j in 1:M],
        C13 * S[j]^5 +
        (
            V13[j] * S[j]^2
            - 3.0 * V12[j] * S[j] * S1[j]
            + 3.0 * V11[j] * S1[j]^2
            + V11[j] * S[j] * S2[j]
        ) >= 0
    )

    @NLconstraint(model, gx7[j in 1:M],
        C21 * S[j] - V21[j] >= 0
    )

    @NLconstraint(model, gx8[j in 1:M],
        C21 * S[j] + V21[j] >= 0
    )

    @NLconstraint(model, gx9[j in 1:M],
        C22 * S[j]^3 - (V22[j] * S[j] - V21[j] * S1[j]) >= 0
    )

    @NLconstraint(model, gx10[j in 1:M],
        C22 * S[j]^3 + (V22[j] * S[j] - V21[j] * S1[j]) >= 0
    )

    @NLconstraint(model, gx11[j in 1:M],
        C23 * S[j]^5 -
        (
            V23[j] * S[j]^2
            - 3.0 * V22[j] * S[j] * S1[j]
            + 3.0 * V21[j] * S1[j]^2
            + V21[j] * S[j] * S2[j]
        ) >= 0
    )

    @NLconstraint(model, gx12[j in 1:M],
        C23 * S[j]^5 +
        (
            V23[j] * S[j]^2
            - 3.0 * V22[j] * S[j] * S1[j]
            + 3.0 * V21[j] * S1[j]^2
            + V21[j] * S[j] * S2[j]
        ) >= 0
    )

    @NLconstraint(model, gx13[j in 1:M],
        C31 * S[j] - V31[j] >= 0
    )

    @NLconstraint(model, gx14[j in 1:M],
        C31 * S[j] + V31[j] >= 0
    )

    @NLconstraint(model, gx15[j in 1:M],
        C32 * S[j]^3 - (V32[j] * S[j] - V31[j] * S1[j]) >= 0
    )

    @NLconstraint(model, gx16[j in 1:M],
        C32 * S[j]^3 + (V32[j] * S[j] - V31[j] * S1[j]) >= 0
    )

    @NLconstraint(model, gx17[j in 1:M],
        C33 * S[j]^5 -
        (
            V33[j] * S[j]^2
            - 3.0 * V32[j] * S[j] * S1[j]
            + 3.0 * V31[j] * S1[j]^2
            + V31[j] * S[j] * S2[j]
        ) >= 0
    )

    @NLconstraint(model, gx18[j in 1:M],
        C33 * S[j]^5 +
        (
            V33[j] * S[j]^2
            - 3.0 * V32[j] * S[j] * S1[j]
            + 3.0 * V31[j] * S1[j]^2
            + V31[j] * S[j] * S2[j]
        ) >= 0
    )

    return model
end
model

# ============================================================
# Exemplo de uso
# ============================================================
#
# Preencha aqui com os valores reais do benchmark.
#
# using Ipopt
#
# model = build_model(
#     N = 100,
#     M = 100,
#     C11 = 1.0,
#     C12 = 1.0,
#     C13 = 1.0,
#     C21 = 1.0,
#     C22 = 1.0,
#     C23 = 1.0,
#     C31 = 1.0,
#     C32 = 1.0,
#     C33 = 1.0,
#     optimizer = Ipopt.Optimizer
# )
#
# optimize!(model)
#
# println("Status: ", termination_status(model))
#
# if has_values(model)
#     println("Objetivo: ", objective_value(model))
# end
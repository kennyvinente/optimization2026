using JuMP

# ============================================================
# rocket_12800_jump.jl
# Tradução corrigida do arquivo rocket_12800.mod para JuMP
# Goddard Rocket Problem
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros do problema
# ------------------------------------------------------------

nh = 12800

v_0 = 0.0

# Normalização
g_0 = 1.0
h_0 = 1.0
m_0 = 1.0

T_c = 3.5
h_c = 500.0
v_c = 620.0
m_c = 0.6

# Parâmetros derivados
c = 0.5 * sqrt(g_0 * h_0)
m_final = m_c * m_0
D_c = 0.5 * v_c * (m_0 / g_0)
T_max = T_c * (m_0 * g_0)

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, h[0:nh] >= h_0)
@variable(model, v[0:nh] >= 0.0)
@variable(model, m_final <= m[0:nh] <= m_0)
@variable(model, 0.0 <= T[0:nh] <= T_max)

@variable(model, step >= 0.0)
@variable(model, tf >= 0.0)

# ------------------------------------------------------------
# Expressões auxiliares
# ------------------------------------------------------------

@NLexpression(
    model,
    D[i in 0:nh],
    D_c * v[i]^2 * exp(-h_c * (h[i] - h_0) / h_0)
)

@NLexpression(
    model,
    g[i in 0:nh],
    g_0 * (h_0 / h[i])^2
)

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

for k in 0:nh
    τ = k / nh

    # Chute inicial suave para altura
    set_start_value(h[k], h_0 + 0.1 * τ)

    # Chute inicial parabólico para velocidade
    set_start_value(v[k], τ * (1.0 - τ))

    # Massa decrescendo linearmente de m_0 até m_final
    set_start_value(m[k], m_0 + (m_final - m_0) * τ)

    # Empuxo inicial intermediário
    set_start_value(T[k], 0.5 * T_max)
end

set_start_value(step, 1.0 / nh)
set_start_value(tf, 1.0)

# ------------------------------------------------------------
# Objetivo
# ------------------------------------------------------------
# O problema maximiza a altura final h[nh].
# No AMPL pode aparecer como "final_velocity", mas a expressão é h[nh].

@objective(model, Max, h[nh])

# ------------------------------------------------------------
# Relação entre tempo final e passo
# ------------------------------------------------------------

@NLconstraint(model, tf_eqn, tf == step * nh)

# ------------------------------------------------------------
# Equações trapezoidais
# ------------------------------------------------------------

@NLconstraint(
    model,
    h_eqn[j in 1:nh],
    h[j] == h[j - 1] + 0.5 * step * (v[j] + v[j - 1])
)

@NLconstraint(
    model,
    v_eqn[j in 1:nh],
    v[j] ==
    v[j - 1] +
    0.5 * step * (
        (T[j] - D[j] - m[j] * g[j]) / m[j] +
        (T[j - 1] - D[j - 1] - m[j - 1] * g[j - 1]) / m[j - 1]
    )
)

@NLconstraint(
    model,
    m_eqn[j in 1:nh],
    m[j] == m[j - 1] - 0.5 * step * (T[j] + T[j - 1]) / c
)

# ------------------------------------------------------------
# Condições de contorno
# ------------------------------------------------------------

@constraint(model, h_ic, h[0] == h_0)
@constraint(model, v_ic, v[0] == v_0)
@constraint(model, m_ic, m[0] == m_0)
@constraint(model, m_fc, m[nh] == m_final)

# ------------------------------------------------------------
# Informações para diagnóstico
# ------------------------------------------------------------

println("Modelo rocket_12800 carregado com sucesso.")
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
#     println("Altura final: ", value(h[nh]))
#     println("Tempo final: ", value(tf))
# end
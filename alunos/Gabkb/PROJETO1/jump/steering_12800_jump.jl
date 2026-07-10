using JuMP

# ============================================================
# steering_12800_jump.jl
# Tradução corrigida do arquivo steering_12800.mod para JuMP
# Rocket Steering Problem
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

nh = 12800

a = 100.0

y1_0 = 0.0
y2_0 = 0.0
y3_0 = 0.0
y4_0 = 0.0

y2_n = 5.0
y3_n = 45.0
y4_n = 0.0

u_min = -pi / 2.0
u_max =  pi / 2.0

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, u_min <= u[0:nh] <= u_max)

@variable(model, y1[0:nh])
@variable(model, y2[0:nh])
@variable(model, y3[0:nh])
@variable(model, y4[0:nh])

@variable(model, step >= 0.0)
@variable(model, tf >= 0.0)

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

set_start_value(step, 1.0 / nh)
set_start_value(tf, 1.0)

for k in 0:nh
    τ = k / nh

    # Controle inicial neutro
    set_start_value(u[k], 0.0)

    # Chutes iniciais suaves
    set_start_value(y1[k], 0.0)

    # Interpolação suave de y2: começa em 0 e termina em y2_n
    set_start_value(y2[k], y2_n * (3.0 * τ^2 - 2.0 * τ^3))

    # Interpolação linear de y3: começa em 0 e termina em y3_n
    set_start_value(y3[k], y3_n * τ)

    # Chute parabólico para y4: começa e termina em 0
    set_start_value(y4[k], 6.0 * y2_n * τ * (1.0 - τ))
end

# ------------------------------------------------------------
# Objetivo
# ------------------------------------------------------------

@objective(model, Min, tf)

# ------------------------------------------------------------
# Equação do tempo final
# ------------------------------------------------------------
# Esta equação é linear. Não precisa ser @NLconstraint.

@constraint(model, tf_eqn, tf == step * nh)

# ------------------------------------------------------------
# Dinâmica trapezoidal
# ------------------------------------------------------------

@NLconstraint(
    model,
    y1_eqn[j in 0:nh-1],
    y1[j + 1] == y1[j] + 0.5 * step * (y3[j] + y3[j + 1])
)

@NLconstraint(
    model,
    y2_eqn[j in 0:nh-1],
    y2[j + 1] == y2[j] + 0.5 * step * (y4[j] + y4[j + 1])
)

@NLconstraint(
    model,
    y3_eqn[j in 0:nh-1],
    y3[j + 1] == y3[j] + 0.5 * step * (
        a * cos(u[j]) + a * cos(u[j + 1])
    )
)

@NLconstraint(
    model,
    y4_eqn[j in 0:nh-1],
    y4[j + 1] == y4[j] + 0.5 * step * (
        a * sin(u[j]) + a * sin(u[j + 1])
    )
)

# ------------------------------------------------------------
# Condições iniciais
# ------------------------------------------------------------

@constraint(model, y1_ic, y1[0] == y1_0)
@constraint(model, y2_ic, y2[0] == y2_0)
@constraint(model, y3_ic, y3[0] == y3_0)
@constraint(model, y4_ic, y4[0] == y4_0)

# ------------------------------------------------------------
# Condições finais
# ------------------------------------------------------------

@constraint(model, y2_fc, y2[nh] == y2_n)
@constraint(model, y3_fc, y3[nh] == y3_n)
@constraint(model, y4_fc, y4[nh] == y4_n)

# ------------------------------------------------------------
# Informações para diagnóstico
# ------------------------------------------------------------

println("Modelo steering_12800 carregado com sucesso.")
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
#     println("Tempo final: ", value(tf))
#     println("Step: ", value(step))
# end
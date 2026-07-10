using JuMP
using SparseArrays

# ============================================================
# robot_1600_jump.jl
# Modelo corrigido para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros do problema
# ------------------------------------------------------------

nh = 1600

L = 5.0

max_u_rho = 1.0
max_u_the = 1.0
max_u_phi = 1.0

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, 0.0 <= rho[0:nh] <= L)
@variable(model, -pi <= the[0:nh] <= pi)
@variable(model, 0.0 <= phi[0:nh] <= pi)

@variable(model, rho_dot[0:nh])
@variable(model, the_dot[0:nh])
@variable(model, phi_dot[0:nh])

@variable(model, -max_u_rho <= u_rho[0:nh] <= max_u_rho)
@variable(model, -max_u_the <= u_the[0:nh] <= max_u_the)
@variable(model, -max_u_phi <= u_phi[0:nh] <= max_u_phi)

@variable(model, step >= 0.0)
@variable(model, tf >= 0.0)

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

set_start_value(step, 1.0 / nh)
set_start_value(tf, 1.0)

for k in 0:nh
    set_start_value(rho[k], 4.5)
    set_start_value(the[k], (2.0 * pi / 3.0) * (k / nh)^2)
    set_start_value(phi[k], pi / 4.0)

    set_start_value(rho_dot[k], 0.0)
    set_start_value(the_dot[k], (4.0 * pi / 3.0) * (k / nh))
    set_start_value(phi_dot[k], 0.0)

    set_start_value(u_rho[k], 0.0)
    set_start_value(u_the[k], 0.0)
    set_start_value(u_phi[k], 0.0)
end

# ------------------------------------------------------------
# Expressões auxiliares
# ------------------------------------------------------------
# No código convertido automaticamente, I_the e I_phi estavam como
# variáveis, mas isso estava errado. Elas são expressões dependentes
# de rho e phi.

@NLexpression(
    model,
    I_the[i in 0:nh],
    ((L - rho[i])^3 + rho[i]^3) * (sin(phi[i]))^2 / 3.0
)

@NLexpression(
    model,
    I_phi[i in 0:nh],
    ((L - rho[i])^3 + rho[i]^3) / 3.0
)

# ------------------------------------------------------------
# Objetivo
# ------------------------------------------------------------

@objective(model, Min, tf)

# ------------------------------------------------------------
# Equação do tempo final
# ------------------------------------------------------------

@NLconstraint(
    model,
    tf_eqn,
    tf == step * nh
)

# ------------------------------------------------------------
# Dinâmica trapezoidal
# ------------------------------------------------------------

@NLconstraint(
    model,
    rho_eqn[j in 1:nh],
    rho[j] == rho[j - 1] + 0.5 * step * (rho_dot[j] + rho_dot[j - 1])
)

@NLconstraint(
    model,
    the_eqn[j in 1:nh],
    the[j] == the[j - 1] + 0.5 * step * (the_dot[j] + the_dot[j - 1])
)

@NLconstraint(
    model,
    phi_eqn[j in 1:nh],
    phi[j] == phi[j - 1] + 0.5 * step * (phi_dot[j] + phi_dot[j - 1])
)

@NLconstraint(
    model,
    u_rho_eqn[j in 1:nh],
    rho_dot[j] == rho_dot[j - 1] +
    0.5 * step * (u_rho[j] + u_rho[j - 1]) / L
)

@NLconstraint(
    model,
    u_the_eqn[j in 1:nh],
    the_dot[j] == the_dot[j - 1] +
    0.5 * step * (
        u_the[j] / I_the[j] +
        u_the[j - 1] / I_the[j - 1]
    )
)

@NLconstraint(
    model,
    u_phi_eqn[j in 1:nh],
    phi_dot[j] == phi_dot[j - 1] +
    0.5 * step * (
        u_phi[j] / I_phi[j] +
        u_phi[j - 1] / I_phi[j - 1]
    )
)

# ------------------------------------------------------------
# Condições iniciais
# ------------------------------------------------------------

@constraint(model, rho_0_eqn, rho[0] == 4.5)
@constraint(model, the_0_eqn, the[0] == 0.0)
@constraint(model, phi_0_eqn, phi[0] == pi / 4.0)

@constraint(model, rho_dot_0_eqn, rho_dot[0] == 0.0)
@constraint(model, the_dot_0_eqn, the_dot[0] == 0.0)
@constraint(model, phi_dot_0_eqn, phi_dot[0] == 0.0)

# ------------------------------------------------------------
# Condições finais
# ------------------------------------------------------------

@constraint(model, rho_f_eqn, rho[nh] == 4.5)
@constraint(model, the_f_eqn, the[nh] == 2.0 * pi / 3.0)
@constraint(model, phi_f_eqn, phi[nh] == pi / 4.0)

@constraint(model, rho_dot_f_eqn, rho_dot[nh] == 0.0)
@constraint(model, the_dot_f_eqn, the_dot[nh] == 0.0)
@constraint(model, phi_dot_f_eqn, phi_dot[nh] == 0.0)

# ------------------------------------------------------------
# Informações para diagnóstico
# ------------------------------------------------------------

println("Modelo robot_1600 carregado com sucesso.")
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
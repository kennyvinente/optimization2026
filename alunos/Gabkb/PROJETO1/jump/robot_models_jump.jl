using JuMP

# ============================================================
# robot_models_jump.jl corrigido
#
# Modelos disponíveis:
# - robot_a
# - robot_b
# - robot_c
# - robot_1600
#
# Para escolher o modelo antes do include:
#
# ENV["ROBOT_MODEL_NAME"] = "robot_a"
# include("robot_models_jump.jl")
#
# Se não definir nada, carrega robot_a por padrão.
# ============================================================

function robot_constants(nome::String)
    if nome == "robot_a"
        return Dict(
            :C11 => 2.0, :C12 => 8.0,  :C13 => 250.0,
            :C21 => 3.0, :C22 => 18.0, :C23 => 650.0,
            :C31 => 4.0, :C32 => 50.0, :C33 => 1000.0
        )

    elseif nome == "robot_b"
        return Dict(
            :C11 => 1.0, :C12 => 3.0, :C13 => 100.0,
            :C21 => 1.0, :C22 => 3.0, :C23 => 100.0,
            :C31 => 1.0, :C32 => 3.0, :C33 => 100.0
        )

    elseif nome == "robot_c"
        return Dict(
            :C11 => 2.0, :C12 => 8.0,  :C13 => 25.0,
            :C21 => 3.0, :C22 => 18.0, :C23 => 65.0,
            :C31 => 4.0, :C32 => 50.0, :C33 => 100.0
        )

    else
        error("Nome inválido para modelo spline: $(nome)")
    end
end


function build_robot_spline_model(nome::String)

    C = robot_constants(nome)

    C11 = C[:C11]
    C12 = C[:C12]
    C13 = C[:C13]

    C21 = C[:C21]
    C22 = C[:C22]
    C23 = C[:C23]

    C31 = C[:C31]
    C32 = C[:C32]
    C33 = C[:C33]

    N = 1001
    M = 4001

    H = 1.0 / (N - 1)

    # Correção importante:
    # Antes havia um zero extra no começo de TP e K.
    # Isso deslocava os índices e fazia o último ponto t = 1 não ser usado.
    TP = [(i - 1.0) / (M - 1.0) for i in 1:M]

    K = [
        round(Int, TP[i] / H + 1.0e-6 + 1.0)
        for i in 1:M
    ]

    BB = zeros(Float64, N)

    for i in 1:N
        if i == 1
            BB[i] = 0.5 * H
        elseif i == 2
            BB[i] = 23.0 * H / 24.0
        elseif i == N
            BB[i] = 0.5 * H
        elseif i == N - 1
            BB[i] = 23.0 * H / 24.0
        else
            BB[i] = H
        end
    end

    # Cada ponto i usa no máximo 4 variáveis X.
    JIDX = fill(1, M, 4)

    VI  = zeros(Float64, M, 4)
    VI1 = zeros(Float64, M, 4)
    VI2 = zeros(Float64, M, 4)

    for i in 1:M
        kk = K[i]

        delta_left  = TP[i] - (kk - 1) * H
        delta_right = kk * H - TP[i]

        for j in max(1, kk - 1):min(N, kk + 2)

            q = kk - j + 3

            if q < 1 || q > 4
                continue
            end

            JIDX[i, q] = j

            if q == 1
                VI[i, q]  = delta_left^3 / (6.0 * H^3)
                VI1[i, q] = delta_left^2 / (2.0 * H^3)
                VI2[i, q] = delta_left / H^3

            elseif q == 2
                VI[i, q] =
                    1.0 / 6.0 +
                    0.5 * delta_left / H +
                    0.5 * delta_left^2 / H^2 -
                    0.5 * delta_left^3 / H^3

                VI1[i, q] =
                    0.5 / H +
                    delta_left / H^2 -
                    1.5 * delta_left^2 / H^3

                VI2[i, q] =
                    1.0 / H^2 -
                    3.0 * delta_left / H^3

            elseif q == 3
                VI[i, q] =
                    1.0 / 6.0 +
                    0.5 * delta_right / H +
                    0.5 * delta_right^2 / H^2 -
                    0.5 * delta_right^3 / H^3

                VI1[i, q] =
                    -0.5 / H -
                    delta_right / H^2 +
                    1.5 * delta_right^2 / H^3

                VI2[i, q] =
                    1.0 / H^2 -
                    3.0 * delta_right / H^3

            elseif q == 4
                VI[i, q]  = delta_right^3 / (6.0 * H^3)
                VI1[i, q] = -delta_right^2 / (2.0 * H^3)
                VI2[i, q] = delta_right / H^3
            end
        end
    end

    V11 = zeros(Float64, M)
    V12 = zeros(Float64, M)
    V13 = zeros(Float64, M)

    V21 = zeros(Float64, M)
    V22 = zeros(Float64, M)
    V23 = zeros(Float64, M)

    V31 = zeros(Float64, M)
    V32 = zeros(Float64, M)
    V33 = zeros(Float64, M)

    for i in 1:M
        t = TP[i]

        A1 = 30.0 * t^2 * ((t - 2.0) * t + 1.0)
        A2 = 60.0 * t * ((2.0 * t - 3.0) * t + 1.0)
        A3 = (360.0 * t - 360.0) * t + 60.0

        g    = 4.7 * t^3 * ((6.0 * t - 15.0) * t + 10.0)
        gp   = 4.7 * A1
        gpp  = 4.7 * A2
        gppp = 4.7 * A3

        V11[i] = 1.5 * A1
        V12[i] = 1.5 * A2
        V13[i] = 1.5 * A3

        V21[i] = -0.5 * cos(g) * gp
        V22[i] = -0.5 * (-sin(g) * gp^2 + cos(g) * gpp)
        V23[i] = -0.5 * (-cos(g) * gp^3 - 3.0 * sin(g) * gp * gpp + cos(g) * gppp)

        V31[i] = -1.3 * A1
        V32[i] = -1.3 * A2
        V33[i] = -1.3 * A3
    end

    model = Model()

    @variable(model, X[1:N])

    for i in 1:N
        set_start_value(X[i], 1.491400623321533)
    end

    @NLexpression(
        model,
        SUM[i in 1:M],
        sum(VI[i, p] * X[JIDX[i, p]] for p in 1:4)
    )

    @NLexpression(
        model,
        SUM1[i in 1:M],
        sum(VI1[i, p] * X[JIDX[i, p]] for p in 1:4)
    )

    @NLexpression(
        model,
        SUM2[i in 1:M],
        sum(VI2[i, p] * X[JIDX[i, p]] for p in 1:4)
    )

    @objective(
        model,
        Min,
        sum(BB[i] * X[i] for i in 1:N)
    )

    @NLconstraint(model, gx1[i in 1:M], C11 * SUM[i] - V11[i] >= 0)
    @NLconstraint(model, gx2[i in 1:M], C11 * SUM[i] + V11[i] >= 0)

    @NLconstraint(
        model,
        gx3[i in 1:M],
        C12 * SUM[i]^3 - (V12[i] * SUM[i] - V11[i] * SUM1[i]) >= 0
    )

    @NLconstraint(
        model,
        gx4[i in 1:M],
        C12 * SUM[i]^3 + (V12[i] * SUM[i] - V11[i] * SUM1[i]) >= 0
    )

    @NLconstraint(
        model,
        gx5[i in 1:M],
        C13 * SUM[i]^5 -
        (
            V13[i] * SUM[i]^2 -
            3.0 * V12[i] * SUM[i] * SUM1[i] +
            3.0 * V11[i] * SUM1[i]^2 +
            V11[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    @NLconstraint(
        model,
        gx6[i in 1:M],
        C13 * SUM[i]^5 +
        (
            V13[i] * SUM[i]^2 -
            3.0 * V12[i] * SUM[i] * SUM1[i] +
            3.0 * V11[i] * SUM1[i]^2 +
            V11[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    @NLconstraint(model, gx7[i in 1:M], C21 * SUM[i] - V21[i] >= 0)
    @NLconstraint(model, gx8[i in 1:M], C21 * SUM[i] + V21[i] >= 0)

    @NLconstraint(
        model,
        gx9[i in 1:M],
        C22 * SUM[i]^3 - (V22[i] * SUM[i] - V21[i] * SUM1[i]) >= 0
    )

    @NLconstraint(
        model,
        gx10[i in 1:M],
        C22 * SUM[i]^3 + (V22[i] * SUM[i] - V21[i] * SUM1[i]) >= 0
    )

    @NLconstraint(
        model,
        gx11[i in 1:M],
        C23 * SUM[i]^5 -
        (
            V23[i] * SUM[i]^2 -
            3.0 * V22[i] * SUM[i] * SUM1[i] +
            3.0 * V21[i] * SUM1[i]^2 +
            V21[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    @NLconstraint(
        model,
        gx12[i in 1:M],
        C23 * SUM[i]^5 +
        (
            V23[i] * SUM[i]^2 -
            3.0 * V22[i] * SUM[i] * SUM1[i] +
            3.0 * V21[i] * SUM1[i]^2 +
            V21[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    @NLconstraint(model, gx13[i in 1:M], C31 * SUM[i] - V31[i] >= 0)
    @NLconstraint(model, gx14[i in 1:M], C31 * SUM[i] + V31[i] >= 0)

    @NLconstraint(
        model,
        gx15[i in 1:M],
        C32 * SUM[i]^3 - (V32[i] * SUM[i] - V31[i] * SUM1[i]) >= 0
    )

    @NLconstraint(
        model,
        gx16[i in 1:M],
        C32 * SUM[i]^3 + (V32[i] * SUM[i] - V31[i] * SUM1[i]) >= 0
    )

    @NLconstraint(
        model,
        gx17[i in 1:M],
        C33 * SUM[i]^5 -
        (
            V33[i] * SUM[i]^2 -
            3.0 * V32[i] * SUM[i] * SUM1[i] +
            3.0 * V31[i] * SUM1[i]^2 +
            V31[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    @NLconstraint(
        model,
        gx18[i in 1:M],
        C33 * SUM[i]^5 +
        (
            V33[i] * SUM[i]^2 -
            3.0 * V32[i] * SUM[i] * SUM1[i] +
            3.0 * V31[i] * SUM1[i]^2 +
            V31[i] * SUM[i] * SUM2[i]
        ) >= 0
    )

    println("Modelo ", nome, " carregado com sucesso.")
    println("Variáveis: ", num_variables(model))
    println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

    return model
end


function build_robot_1600_model()

    nh = 1600

    L = 5.0

    max_u_rho = 1.0
    max_u_the = 1.0
    max_u_phi = 1.0

    model = Model()

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

    @objective(model, Min, tf)

    @NLconstraint(model, tf_eqn, tf == step * nh)

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
        rho_dot[j] == rho_dot[j - 1] + 0.5 * step * (u_rho[j] + u_rho[j - 1]) / L
    )

    @NLconstraint(
        model,
        u_the_eqn[j in 1:nh],
        the_dot[j] == the_dot[j - 1] +
        0.5 * step * (u_the[j] / I_the[j] + u_the[j - 1] / I_the[j - 1])
    )

    @NLconstraint(
        model,
        u_phi_eqn[j in 1:nh],
        phi_dot[j] == phi_dot[j - 1] +
        0.5 * step * (u_phi[j] / I_phi[j] + u_phi[j - 1] / I_phi[j - 1])
    )

    @constraint(model, rho_0_eqn, rho[0] == 4.5)
    @constraint(model, the_0_eqn, the[0] == 0.0)
    @constraint(model, phi_0_eqn, phi[0] == pi / 4.0)

    @constraint(model, rho_f_eqn, rho[nh] == 4.5)
    @constraint(model, the_f_eqn, the[nh] == 2.0 * pi / 3.0)
    @constraint(model, phi_f_eqn, phi[nh] == pi / 4.0)

    @constraint(model, rho_dot_0_eqn, rho_dot[0] == 0.0)
    @constraint(model, the_dot_0_eqn, the_dot[0] == 0.0)
    @constraint(model, phi_dot_0_eqn, phi_dot[0] == 0.0)

    @constraint(model, rho_dot_f_eqn, rho_dot[nh] == 0.0)
    @constraint(model, the_dot_f_eqn, the_dot[nh] == 0.0)
    @constraint(model, phi_dot_f_eqn, phi_dot[nh] == 0.0)

    println("Modelo robot_1600 carregado com sucesso.")
    println("Variáveis: ", num_variables(model))
    println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

    return model
end


# ============================================================
# CRIAÇÃO DO MODELO GLOBAL
# ============================================================
#
# Seu diagnosticador espera que depois do include exista uma
# variável chamada model.
#
# Por padrão, carrega robot_a.
#
# Para escolher outro:
#
# ENV["ROBOT_MODEL_NAME"] = "robot_b"
# include("robot_models_jump.jl")
#
# ============================================================

ROBOT_MODEL_NAME = get(ENV, "ROBOT_MODEL_NAME", "robot_a")

if ROBOT_MODEL_NAME == "robot_1600"
    model = build_robot_1600_model()
elseif ROBOT_MODEL_NAME in ["robot_a", "robot_b", "robot_c"]
    model = build_robot_spline_model(ROBOT_MODEL_NAME)
else
    error("ROBOT_MODEL_NAME inválido: $(ROBOT_MODEL_NAME)")
end
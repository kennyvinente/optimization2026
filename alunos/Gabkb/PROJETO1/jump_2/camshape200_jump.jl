# camshape200 convertido de GAMS scalar para JuMP
# NLP: 399 variaveis x + objvar
# Equacoes: e1, e2..e202, e203..e401
# Uso:
#   using JuMP, Ipopt
#   include("camshape200_jump.jl")
#   set_optimizer(model, Ipopt.Optimizer)
#   optimize!(model)

using JuMP

function build_camshape200_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    # Parametros do camshape200
    N = 200
    h_obj = 0.015707963267949
    alpha = 1.99996091355262
    delta = 0.00937788851817849
    x1_up = 1.00003908797519
    xN_lo = 1.99062211148182

    # x[1:200] sao os pontos principais; x[201:399] sao variaveis de diferenca.
    @variable(model, x[1:399], base_name = "x")
    @variable(model, objvar, base_name = "objvar")

    # Bounds: x1, x2..x199, x200.
    set_lower_bound(x[1], 1.0)
    set_upper_bound(x[1], x1_up)

    for i in 2:(N-1)
        set_lower_bound(x[i], 1.0)
        set_upper_bound(x[i], 2.0)
    end

    set_lower_bound(x[N], xN_lo)
    set_upper_bound(x[N], 2.0)

    # No GAMS convertido, x201 nao aparece com bound nao padrao; fica livre.
    # x202..x399 tem bounds simetricos +/- delta.
    for i in (N+2):(2N-1)
        set_lower_bound(x[i], -delta)
        set_upper_bound(x[i],  delta)
    end

    if set_starts
        # Chutes iniciais conforme o GAMS colado.
        set_start_value(x[1], x1_up)
        for i in 2:(N-1)
            set_start_value(x[i], 1.5)
        end
        # O GAMS nao mostrou level para x200; usamos um valor viavel dentro do bound.
        set_start_value(x[N], (xN_lo + 2.0) / 2)
        # Variaveis livres/de diferenca: iniciar em zero.
        for i in (N+1):(2N-1)
            set_start_value(x[i], 0.0)
        end
        sum_x_start = x1_up + 1.5 * (N - 2) + (xN_lo + 2.0) / 2
        set_start_value(objvar, -h_obj * sum_x_start)
    end

    @objective(model, Min, objvar)

    # e1: -h_obj * sum(x[1:N]) - objvar == 0
    @constraint(model, e1, -h_obj * sum(x[i] for i in 1:N) - objvar == 0)

    # e2..e199: (-x_i*x_{i+1}) - x_{i+1}*x_{i+2} + alpha*x_i*x_{i+2} <= 0
    @constraint(model, e_mid[i in 1:(N-2)],
        -x[i] * x[i+1] - x[i+1] * x[i+2] + alpha * x[i] * x[i+2] <= 0
    )

    # e200: (-x1*x2) - x1 + alpha*x2 <= 0
    @constraint(model, e_left,
        -x[1] * x[2] - x[1] + alpha * x[2] <= 0
    )

    # e201: (-x199*x200) - 2*x200 + 2*alpha*x199 <= 0
    @constraint(model, e_right,
        -x[N-1] * x[N] - 2.0 * x[N] + (2.0 * alpha) * x[N-1] <= 0
    )

    # e202: alpha*x200^2 - 4*x200 <= 0
    @constraint(model, e_tip,
        alpha * x[N]^2 - 4.0 * x[N] <= 0
    )

    # e203..e401: x_i - x_{i+1} + x_{N+i} == 0, i=1..199
    @constraint(model, e_diff[i in 1:(N-1)],
        x[i] - x[i+1] + x[N+i] == 0
    )

    return model, x, objvar
end

model, x, objvar = build_camshape200_model()

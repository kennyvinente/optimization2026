# catmix200_jump.jl
# Conversão manual/paramétrica do modelo GAMS Convert "catmix200" para JuMP.
#
# Modelo original:
# - 604 variáveis contínuas: x1..x603 e objvar
# - 401 equações de igualdade
# - NLP minimizando objvar
#
# Observação:
# - Mantém objvar e a equação e1 para preservar a estrutura do GAMS.
# - Usa a interface atual do JuMP, sem @NLconstraint/@NLobjective.

using JuMP

"""
    build_catmix200_model(; optimizer=nothing, set_starts=true)

Constrói o modelo JuMP do problema `catmix200`.

Retorna:
    model, x, objvar
"""
function build_catmix200_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    N = 200
    dt = 0.0025

    # x[1]..x[603] representam x1..x603 do GAMS.
    @variable(model, x[1:603])
    @variable(model, objvar)

    # Positive Variables x1..x201,x403;
    # depois o GAMS também impõe x1..x201.up = 1.
    for i in 1:(N + 1)
        set_lower_bound(x[i], 0.0)
        set_upper_bound(x[i], 1.0)
    end

    # x202.fx = 1
    fix(x[N + 2], 1.0; force=true)

    # x403.fx = 0
    # x403 também é Positive Variable no GAMS, mas fixar em 0 já resolve.
    fix(x[2N + 3], 0.0; force=true)

    if set_starts
        # Níveis não-padrão informados pelo GAMS:
        # x203.l .. x402.l = 1
        for i in (N + 3):(2N + 2)
            set_start_value(x[i], 1.0)
        end

        # Chutes razoáveis para evitar começar exatamente na borda em Ipopt.
        # Se quiser imitar o GAMS de forma mais literal, troque por 0.0.
        for i in 1:(N + 1)
            set_start_value(x[i], 0.5)
        end

        set_start_value(x[N + 2], 1.0)
        set_start_value(x[2N + 3], 0.0)

        # As variáveis x404..x603 não têm nível não-padrão no GAMS.
        for i in (2N + 4):(3N + 3)
            set_start_value(x[i], 0.0)
        end
    end

    # Objetivo
    @objective(model, Min, objvar)

    # Índices base:
    # y0 = x202, y_i = x[202+i], i=1..200
    # z0 = x403, z_i = x[403+i], i=1..200
    y0 = N + 2
    z0 = 2N + 3

    # e1..  - x402 - x603 + objvar =E= -1;
    @constraint(model, e1, -x[y0 + N] - x[z0 + N] + objvar == -1.0)

    # e2..e201:
    # y_i - (dt*(u_i*(10*z_{i-1} - y_{i-1}) +
    #             u_{i+1}*(10*z_i - y_i)) + y_{i-1}) = 0
    @constraint(model, e_y[i in 1:N],
        x[y0 + i] -
        (
            dt * (
                x[i]     * (10.0 * x[z0 + i - 1] - x[y0 + i - 1]) +
                x[i + 1] * (10.0 * x[z0 + i]     - x[y0 + i])
            ) +
            x[y0 + i - 1]
        ) == 0.0
    )

    # e202..e401:
    # z_i - (dt*(u_i*(y_{i-1} - 10*z_{i-1}) - (1-u_i)*z_{i-1}
    #           + u_{i+1}*(y_i - 10*z_i) - (1-u_{i+1})*z_i)
    #        + z_{i-1}) = 0
    @constraint(model, e_z[i in 1:N],
        x[z0 + i] -
        (
            dt * (
                x[i]     * (x[y0 + i - 1] - 10.0 * x[z0 + i - 1]) -
                (1.0 - x[i]) * x[z0 + i - 1] +
                x[i + 1] * (x[y0 + i]     - 10.0 * x[z0 + i]) -
                (1.0 - x[i + 1]) * x[z0 + i]
            ) +
            x[z0 + i - 1]
        ) == 0.0
    )

    return model, x, objvar
end

model, x, objvar = build_catmix200_model()

# catmix100_jump.jl
# Conversão manual/paramétrica do modelo GAMS Convert "catmix100" para JuMP.
#
# Modelo original:
# - 304 variáveis contínuas: x1..x303 e objvar
# - 201 equações de igualdade
# - NLP minimizando objvar
#
# Observação:
# - Mantém objvar e a equação e1 para preservar a estrutura do GAMS.
# - Usa a interface atual do JuMP, sem @NLconstraint/@NLobjective.

using JuMP

"""
    build_catmix100_model(; optimizer=nothing, set_starts=true)

Constrói o modelo JuMP do problema `catmix100`.

Retorna:
    model, x, objvar
"""
function build_catmix100_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    N = 100

    # x[1]..x[303] representam x1..x303 do GAMS.
    @variable(model, x[1:303])
    @variable(model, objvar)

    # Positive Variables x1..x101,x203;
    # depois o GAMS também impõe x1..x101.up = 1.
    for i in 1:101
        set_lower_bound(x[i], 0.0)
        set_upper_bound(x[i], 1.0)
    end

    # x102.fx = 1
    fix(x[102], 1.0; force=true)

    # x203.fx = 0
    # x203 também é Positive Variable no GAMS, mas fixar em 0 já resolve.
    fix(x[203], 0.0; force=true)

    if set_starts
        # Níveis não-padrão informados pelo GAMS:
        # x103.l .. x202.l = 1
        for i in 103:202
            set_start_value(x[i], 1.0)
        end

        # Chutes razoáveis para evitar começar exatamente na borda em Ipopt.
        # Se quiser imitar o GAMS de forma mais literal, troque por 0.0.
        for i in 1:101
            set_start_value(x[i], 0.5)
        end

        set_start_value(x[102], 1.0)
        set_start_value(x[203], 0.0)

        # As variáveis x204..x303 não têm nível não-padrão no GAMS.
        for i in 204:303
            set_start_value(x[i], 0.0)
        end
    end

    # Objetivo
    @objective(model, Min, objvar)

    # e1..  - x202 - x303 + objvar =E= -1;
    @constraint(model, e1, -x[202] - x[303] + objvar == -1.0)

    # e2..e101:
    # x[102+i] - (0.005*(x[i]*(10*x[202+i] - x[101+i]) +
    #                    x[i+1]*(10*x[203+i] - x[102+i])) + x[101+i]) = 0
    @constraint(model, e_y[i in 1:N],
        x[102 + i] -
        (
            0.005 * (
                x[i]     * (10.0 * x[202 + i] - x[101 + i]) +
                x[i + 1] * (10.0 * x[203 + i] - x[102 + i])
            ) +
            x[101 + i]
        ) == 0.0
    )

    # e102..e201:
    # x[203+i] - (0.005*(x[i]*(x[101+i] - 10*x[202+i]) - (1-x[i])*x[202+i]
    #                  + x[i+1]*(x[102+i] - 10*x[203+i]) - (1-x[i+1])*x[203+i])
    #             + x[202+i]) = 0
    @constraint(model, e_z[i in 1:N],
        x[203 + i] -
        (
            0.005 * (
                x[i]     * (x[101 + i] - 10.0 * x[202 + i]) -
                (1.0 - x[i]) * x[202 + i] +
                x[i + 1] * (x[102 + i] - 10.0 * x[203 + i]) -
                (1.0 - x[i + 1]) * x[203 + i]
            ) +
            x[202 + i]
        ) == 0.0
    )

    return model, x, objvar
end

model, x, objvar = build_catmix100_model()

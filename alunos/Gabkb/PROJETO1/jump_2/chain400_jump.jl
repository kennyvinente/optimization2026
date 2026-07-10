# chain400_jump.jl
# Conversão compacta GAMS/DAG -> JuMP
# Modelo: chain400
#
# Variáveis GAMS:
#   x[1:802]  -> vetor x
#   objvar        -> variável objetivo
#
# Mapeamento:
#   y[i] = x[i],              i = 1,...,401
#   p[i] = x[401 + i],      i = 1,...,401
#
# Restrições:
#   e1              -> definição de objvar
#   e_dyn[i]        -> e2..e401
#   e_length        -> e402
#
# Observação:
#   Este arquivo usa a interface nova do JuMP para expressões não lineares.
#   Não usa @NLobjective nem @NLconstraint.

using JuMP

function build_chain400_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    N = 400
    h = 0.00125

    @variable(model, x[1:(2N + 2)])
    @variable(model, objvar)

    # Bounds fixos do GAMS
    fix(x[1], 1.0; force=true)
    fix(x[N + 1], 3.0; force=true)

    if set_starts
        # Chute inicial equivalente ao GAMS:
        # y(t) = 1 - 2t + 4t^2
        # p(t) = y'(t) = -2 + 8t
        for i in 1:(N + 1)
            t = (i - 1) / N
            set_start_value(x[i], 1.0 - 2.0*t + 4.0*t^2)
            set_start_value(x[N + 1 + i], -2.0 + 8.0*t)
        end
        set_start_value(objvar, 0.0)
    end

    @expression(model, arc[i in 1:(N + 1)], sqrt(1.0 + x[N + 1 + i]^2))

    # e1: -h * integral ponderada + objvar = 0
    @constraint(model, e1,
        objvar ==
            h * (
                x[1] * arc[1] +
                x[N + 1] * arc[N + 1] +
                2.0 * sum(x[i] * arc[i] for i in 2:N)
            )
    )

    # e2..e(N+1): discretização trapezoidal
    @constraint(model, e_dyn[i in 1:N],
        -x[i] + x[i + 1] - h * x[N + 1 + i] - h * x[N + 1 + i + 1] == 0.0
    )

    # e(N+2): restrição de comprimento
    @constraint(model, e_length,
        h * (
            arc[1] +
            arc[N + 1] +
            2.0 * sum(arc[i] for i in 2:N)
        ) == 4.0
    )

    @objective(model, Min, objvar)

    return model, x, objvar
end

model, x, objvar = build_chain400_model()

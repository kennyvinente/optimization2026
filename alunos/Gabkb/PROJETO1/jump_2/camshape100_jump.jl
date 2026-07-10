using JuMP

"""
    build_camshape100_model(; optimizer=nothing, set_starts=true)

Modelo JuMP convertido do GAMS scalar `camshape100`.

Estrutura do GAMS:
- 200 variáveis contínuas: x1..x199 e objvar
- 201 equações
- NLP minimizando objvar

Observação:
- Usa a interface nova do JuMP. Não usa @NLobjective/@NLconstraint.
- Mantém objvar como variável para preservar a estrutura original do GAMS.
"""
function build_camshape100_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    A = 1.99984519984971
    h = 0.0314159265358979
    dmax = 0.0186629266549889

    @variable(model, x[1:199])
    @variable(model, objvar)

    # Bounds do GAMS.
    set_lower_bound(x[1], 1.0)
    set_upper_bound(x[1], 1.00015482411709)

    for i in 2:99
        set_lower_bound(x[i], 1.0)
        set_upper_bound(x[i], 2.0)
    end

    set_lower_bound(x[100], 1.98133707334501)
    set_upper_bound(x[100], 2.0)

    # x[101] fica livre, exatamente como no GAMS scalar colado.
    for i in 102:199
        set_lower_bound(x[i], -dmax)
        set_upper_bound(x[i],  dmax)
    end

    if set_starts
        set_start_value(x[1], 1.00015482411709)
        for i in 2:99
            set_start_value(x[i], 1.5)
        end
        set_start_value(x[100], (1.98133707334501 + 2.0) / 2.0)
        set_start_value(x[101], 0.0)
        for i in 102:199
            set_start_value(x[i], 0.0)
        end
        set_start_value(objvar, -h * sum(start_value(x[i]) for i in 1:100))
    end

    # e1:
    # -h*sum(x1..x100) - objvar == 0
    @constraint(model, e1, -h * sum(x[i] for i in 1:100) - objvar == 0.0)

    # e2..e99:
    # (-x_i*x_{i+1}) - x_{i+1}*x_{i+2} + A*x_i*x_{i+2} <= 0
    @constraint(
        model,
        e_chain[i in 1:98],
        -x[i] * x[i + 1] - x[i + 1] * x[i + 2] + A * x[i] * x[i + 2] <= 0.0
    )

    # e100
    @constraint(model, e100, -x[1] * x[2] - x[1] + A * x[2] <= 0.0)

    # e101
    @constraint(model, e101, -x[99] * x[100] - 2.0 * x[100] + 2.0 * A * x[99] <= 0.0)

    # e102
    @constraint(model, e102, A * x[100]^2 - 4.0 * x[100] <= 0.0)

    # e103..e201:
    # x_i - x_{i+1} + x_{100+i} == 0
    @constraint(
        model,
        e_diff[i in 1:99],
        x[i] - x[i + 1] + x[100 + i] == 0.0
    )

    @objective(model, Min, objvar)

    return model, x, objvar
end

model, x, objvar = build_camshape100_model()

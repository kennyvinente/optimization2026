# chain50_jump.jl
#
# Modelo chain50 convertido de GAMS scalar para JuMP.
# Mantém a estrutura original:
#   - Variáveis x[1:102] e objvar
#   - 52 restrições de igualdade
#   - x[1] fixado em 1
#   - x[51] fixado em 3
#   - objetivo: minimizar objvar
#
# Uso:
#   include("chain50_jump.jl")
#   set_optimizer(model, Ipopt.Optimizer)
#   optimize!(model)

using JuMP

function build_chain50_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    N = 50
    h2 = 0.01

    @variable(model, x[1:102])
    @variable(model, objvar)

    # Bounds/fixações do GAMS
    fix(x[1], 1.0; force=true)
    fix(x[51], 3.0; force=true)

    # Mapeamento dos blocos do GAMS:
    # y_i     -> x[i],      i = 1..51
    # slope_i -> x[i + 51], i = 1..51
    arc_density(i) = sqrt(1.0 + x[i + 51]^2)

    # e1:
    # -0.01 * trapezio(y_i * sqrt(1+s_i^2)) + objvar = 0
    @constraint(
        model,
        obj_definition,
        objvar
        - h2 * (
            x[1] * arc_density(1)
            + sum(2.0 * x[i] * arc_density(i) for i in 2:N)
            + x[N + 1] * arc_density(N + 1)
        ) == 0.0
    )

    # e2..e51:
    # -x_i + x_{i+1} - 0.01*s_i - 0.01*s_{i+1} = 0
    @constraint(
        model,
        chain_dynamics[i in 1:N],
        -x[i] + x[i + 1] - h2 * x[i + 51] - h2 * x[i + 52] == 0.0
    )

    # e52:
    # 0.01 * trapezio(sqrt(1+s_i^2)) = 4
    @constraint(
        model,
        length_constraint,
        h2 * (
            arc_density(1)
            + sum(2.0 * arc_density(i) for i in 2:N)
            + arc_density(N + 1)
        ) == 4.0
    )

    @objective(model, Min, objvar)

    if set_starts
        # Chutes iniciais do GAMS:
        # y_i = 1 - t + t^2, com t = 2*(i-1)/N
        # slope_i = -2 + (8/N)*(i-1)
        y_start(i) = begin
            t = 2.0 * (i - 1) / N
            1.0 - t + t^2
        end
        s_start(i) = -2.0 + (8.0 / N) * (i - 1)

        for i in 1:(N + 1)
            set_start_value(x[i], y_start(i))
            set_start_value(x[i + 51], s_start(i))
        end

        obj_start =
            h2 * (
                y_start(1) * sqrt(1.0 + s_start(1)^2)
                + sum(2.0 * y_start(i) * sqrt(1.0 + s_start(i)^2) for i in 2:N)
                + y_start(N + 1) * sqrt(1.0 + s_start(N + 1)^2)
            )
        set_start_value(objvar, obj_start)
    end

    return model, x, objvar
end

model, x, objvar = build_chain50_model()

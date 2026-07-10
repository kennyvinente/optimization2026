# chain100_jump.jl
#
# Modelo chain100 convertido de GAMS scalar para JuMP.
# Mantém a estrutura original:
#   - Variáveis x[1:202] e objvar
#   - 102 restrições de igualdade
#   - x[1] fixado em 1
#   - x[101] fixado em 3
#   - objetivo: minimizar objvar
#
# Uso:
#   include("chain100_jump.jl")
#   set_optimizer(model, Ipopt.Optimizer)
#   optimize!(model)

using JuMP

function build_chain100_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    N = 100
    h2 = 0.005

    @variable(model, x[1:202])
    @variable(model, objvar)

    # Bounds/fixações do GAMS
    fix(x[1], 1.0; force=true)
    fix(x[101], 3.0; force=true)

    # Funções auxiliares para mapear os blocos do GAMS:
    # y_i     -> x[i],       i = 1..101
    # slope_i -> x[i + 101], i = 1..101
    arc_density(i) = sqrt(1.0 + x[i + 101]^2)

    # e1:
    # -0.005 * trapezio(y_i * sqrt(1+s_i^2)) + objvar = 0
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

    # e2..e101:
    # -x_i + x_{i+1} - 0.005*s_i - 0.005*s_{i+1} = 0
    @constraint(
        model,
        chain_dynamics[i in 1:N],
        -x[i] + x[i + 1] - h2 * x[i + 101] - h2 * x[i + 102] == 0.0
    )

    # e102:
    # 0.005 * trapezio(sqrt(1+s_i^2)) = 4
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
        # y_i = 1 - t + t^2, com t = (i-1)/50
        # slope_i = -2 + 0.08*(i-1)
        y_start(i) = begin
            t = (i - 1) / 50.0
            1.0 - t + t^2
        end
        s_start(i) = -2.0 + 0.08 * (i - 1)

        for i in 1:(N + 1)
            set_start_value(x[i], y_start(i))
            set_start_value(x[i + 101], s_start(i))
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

model, x, objvar = build_chain100_model()

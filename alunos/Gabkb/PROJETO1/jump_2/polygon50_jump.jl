# polygon50_jump.jl
# Modelo polygon50 convertido de GAMS Convert para JuMP em forma compacta.

using JuMP

function build_polygon50_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    N = 50
    @variable(model, x[1:(2 * N)] >= 0)
    @variable(model, objvar)

    # Raios r[1:N] = x[1:N], ângulos θ[1:N] = x[N+1:2N]
    for i in 1:N
        set_upper_bound(x[i], 1.0)
    end
    fix(x[N], 0.0; force=true)
    for i in (N + 1):(2 * N)
        set_upper_bound(x[i], pi)
    end
    fix(x[2 * N], pi; force=true)

    if set_starts
        c = (N + 1) / 2
        for i in 1:(N - 1)
            set_start_value(x[i], 1.0 - ((i - c) / c)^2)
            set_start_value(x[N + i], i * pi / N)
        end
    end

    @constraint(model,
        -0.5 * sum(x[i + 1] * x[i] * sin(x[N + i + 1] - x[N + i]) for i in 1:(N - 1)) - objvar == 0
    )

    # Distância cordal entre todos os pares <= 1
    for i in 1:(N - 1)
        for j in (i + 1):N
            @constraint(model, x[i]^2 + x[j]^2 - 2*x[i]*x[j]*cos(x[N + j] - x[N + i]) <= 1)
        end
    end

    # Ordenação dos ângulos
    for i in 1:(N - 1)
        @constraint(model, x[N + i] - x[N + i + 1] <= 0)
    end

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_polygon50_model()
for i in 1:(2 * 50)
    @eval $(Symbol(:x, i)) = x[$i]
end

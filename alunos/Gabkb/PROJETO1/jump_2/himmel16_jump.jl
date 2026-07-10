using JuMP

function build_himmel16_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:18])
    @variable(model, objvar)

    # Fixed variables from GAMS
    fix(x[1], 0.0; force=true)
    fix(x[7], 0.0; force=true)
    fix(x[8], 0.0; force=true)

    if set_starts
        set_start_value(x[2], 0.5)
        set_start_value(x[3], 0.5)
        set_start_value(x[4], 0.5)
        set_start_value(x[9], 0.4)
        set_start_value(x[10], 0.8)
        set_start_value(x[11], 0.8)
        set_start_value(x[12], 0.4)
    end

    # Pairwise distance constraints for 6 points: coordinates (x[i], x[6+i])
    for i in 1:5
        for j in (i+1):6
            @constraint(model, (x[i] - x[j])^2 + (x[6+i] - x[6+j])^2 <= 1)
        end
    end

    @constraint(model, -sum(x[i] for i in 13:18) - objvar == 0)

    for i in 1:5
        @constraint(model, -0.5*(x[i]*x[6+i+1] - x[6+i]*x[i+1]) + x[12+i] == 0)
    end
    @constraint(model, -0.5*(x[6]*x[7] - x[12]*x[1]) + x[18] == 0)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_himmel16_model()
for i in 1:18
    @eval $(Symbol(:x, i)) = x[$i]
end

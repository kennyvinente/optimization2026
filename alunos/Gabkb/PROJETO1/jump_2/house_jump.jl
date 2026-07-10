using JuMP

function build_house_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:8])
    @variable(model, objvar)

    set_lower_bound(x[4], 40.0); set_upper_bound(x[4], 68.0)
    set_lower_bound(x[6], 56.0); set_upper_bound(x[6], 100.0)
    set_upper_bound(x[7], 3000.0)

    if set_starts
        set_start_value(x[1], 30.0)
        set_start_value(x[4], 68.0)
    end

    @constraint(model, -(x[1]*x[2] + x[5]*x[4]) + x[7] == 0)
    @constraint(model, -x[1]*x[3] + x[8] == 0)
    @constraint(model, -x[7] - x[8] - objvar == 0)
    @constraint(model, -x[2] - x[5] + x[6] == 0)
    @constraint(model, x[1] - (1/3)*x[4] >= 0)
    @constraint(model, x[1] - 0.5*x[4] <= 0)
    @constraint(model, x[2]*(x[4] - x[1]) >= 1500)
    @constraint(model, -0.5*x[2] + x[3] - x[5] == 0)
    @constraint(model, -0.5*x[2] + x[5] >= 0)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_house_model()
for i in 1:8
    @eval $(Symbol(:x, i)) = x[$i]
end

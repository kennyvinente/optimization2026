using JuMP

function build_haverly_model(; optimizer = nothing, set_starts::Bool = true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:12] >= 0)
    @variable(model, objvar)

    set_upper_bound(x[6], 100.0)
    set_upper_bound(x[7], 200.0)

    if set_starts
        for i in 8:12
            set_start_value(x[i], 1.0)
        end
    end

    @constraint(model, e1, x[1] - 6*x[3] - 16*x[4] - 10*x[5] == 0)
    @constraint(model, e2, x[2] - 9*x[6] - 15*x[7] == 0)
    @constraint(model, e3, x[6] - x[8] - x[10] == 0)
    @constraint(model, e4, x[7] - x[9] - x[11] == 0)
    @constraint(model, e5, x[3] + x[4] - x[10] - x[11] == 0)
    @constraint(model, e6, x[5] - x[8] - x[9] == 0)
    @constraint(model, e7, x[12]*(x[10] + x[11]) - 3*x[3] - x[4] == 0)
    @constraint(model, e8, x[12]*x[10] - 2.5*x[10] - 0.5*x[8] <= 0)
    @constraint(model, e9, x[12]*x[11] - 1.5*x[11] + 0.5*x[9] <= 0)
    @constraint(model, e10, x[1] - x[2] - objvar == 0)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_haverly_model()
for i in 1:12
    @eval $(Symbol(:x, i)) = x[$i]
end

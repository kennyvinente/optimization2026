using JuMP

function build_hhfair_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    idx = vcat(1:17, 19:30)
    @variable(model, x[i in idx])
    @variable(model, objvar)

    # Bounds and fixed variables from GAMS
    fix(x[1], 1000.0; force=true)
    set_lower_bound(x[5], 100.0)
    set_lower_bound(x[6], 100.0)
    set_lower_bound(x[7], 100.0)
    set_lower_bound(x[8], 100.0);  set_upper_bound(x[8], 400.0)
    set_lower_bound(x[9], 100.0);  set_upper_bound(x[9], 400.0)
    set_lower_bound(x[10], 100.0); set_upper_bound(x[10], 400.0)
    fix(x[11], 100.0; force=true)
    set_lower_bound(x[25], 0.01)
    set_lower_bound(x[26], 0.01)
    set_lower_bound(x[27], 0.01)

    if set_starts
        set_start_value(x[2], 1000.0)
        set_start_value(x[3], 1000.0)
        set_start_value(x[4], 1000.0)
        set_start_value(x[8], 400.0)
        set_start_value(x[9], 400.0)
        set_start_value(x[10], 400.0)
        set_start_value(x[12], 100.0)
        set_start_value(x[13], 100.0)
        set_start_value(x[14], 100.0)
        set_start_value(x[25], 1.0)
        set_start_value(x[26], 1.0)
        set_start_value(x[27], 1.0)
    end

    @constraint(model, -(x[25] * x[26]^0.944 * x[27]^0.891136) - objvar == 0)

    @constraint(model, -0.01 * (0.5*x[5]^0.5 + 0.5*(1004.72366 - x[8] - x[15])^0.5)^2 + x[25] == 0)
    @constraint(model, -0.01 * (0.5*x[6]^0.5 + 0.5*(1004.72366 - x[9] - x[16])^0.5)^2 + x[26] == 0)
    @constraint(model, -0.01 * (0.5*x[7]^0.5 + 0.5*(1004.72366 - x[10] - x[17])^0.5)^2 + x[27] == 0)

    @constraint(model, -0.07*x[2] - x[8] + x[28] == 0)
    @constraint(model, -0.07*x[3] - x[9] + x[29] == 0)
    @constraint(model, -0.07*x[4] - x[10] + x[30] == 0)

    @constraint(model, x[22] - 0.2*x[28] == 0)
    @constraint(model, x[23] - 0.2*x[29] == 0)
    @constraint(model, x[24] - 0.2*x[30] == 0)

    @constraint(model, x[5] + x[19] + x[22] - x[28] == 0)
    @constraint(model, x[6] + x[20] + x[23] - x[29] == 0)
    @constraint(model, x[7] + x[21] + x[24] - x[30] == 0)

    @constraint(model, x[1] - x[2] + x[11] - x[12] + x[19] == 0)
    @constraint(model, x[2] - x[3] + x[12] - x[13] + x[20] == 0)
    @constraint(model, x[3] - x[4] + x[13] - x[14] + x[21] == 0)

    @constraint(model, x[15]*(x[12] - 0.255905*x[5]) == 1)
    @constraint(model, x[16]*(x[13] - 0.255905*x[6]) == 1)
    @constraint(model, x[17]*(x[14] - 0.255905*x[7]) == 1)

    @constraint(model, x[4] + x[14] == 1100)

    @constraint(model, -0.25846405*x[5] + x[12] >= 0)
    @constraint(model, -0.25846405*x[6] + x[13] >= 0)
    @constraint(model, -0.25846405*x[7] + x[14] >= 0)

    @constraint(model, x[8] + x[15] <= 904.251294)
    @constraint(model, x[9] + x[16] <= 904.251294)
    @constraint(model, x[10] + x[17] <= 904.251294)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_hhfair_model()
for i in vcat(1:17, 19:30)
    @eval $(Symbol(:x, i)) = x[$i]
end

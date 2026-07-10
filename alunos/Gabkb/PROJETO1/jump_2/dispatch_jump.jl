using JuMP

"""
    build_dispatch_model(; optimizer=nothing, set_starts=true)

Modelo JuMP convertido do GAMS `dispatch`.
"""
function build_dispatch_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variables(model, begin
        50.0 <= x1 <= 200.0
        37.5 <= x2 <= 150.0
        45.0 <= x3 <= 180.0
        x4
        objvar
    end)

    if set_starts
        set_start_value(x1, 100.0)
        set_start_value(x2, 75.0)
        set_start_value(x3, 90.0)
        set_start_value(x4, 0.05)
        set_start_value(objvar, 3000.0)
    end

    @objective(model, Min, objvar)

    @constraints(model, begin
        e1, -(0.00533*x1^2 + 11.669*x1 + 0.00889*x2^2 + 10.333*x2 +
              0.00741*x3^2 + 10.833*x3) + objvar == 653.1
        e2, -(0.01*(0.0676*x1*x1 + 0.00953*x1*x2 - 0.00507*x1*x3 +
                    0.00953*x2*x1 + 0.0521*x2*x2 + 0.00901*x2*x3 -
                    0.00507*x3*x1 + 0.00901*x3*x2 + 0.0294*x3*x3) -
              0.000766*x1 - 3.42e-5*x2 + 0.000189*x3) + x4 == 0.040357
        e3, x1 + x2 + x3 - x4 >= 210.0
    end)

    return model
end

model = build_dispatch_model()

# ex5_2_2_case2_jump.jl
# Modelo JuMP convertido de GAMS Convert
# NLP written by GAMS Convert at 07/19/01 13:39:37

using JuMP

function build_ex5_2_2_case2_model(; optimizer = nothing, set_starts::Bool = true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    # Variáveis positivas do GAMS: x1..x9 >= 0
    @variable(model, 0 <= x[1:9])
    @variable(model, objvar)

    # Bounds superiores
    set_upper_bound(x[1], 600.0)
    set_upper_bound(x[2], 200.0)
    for i in 3:9
        set_upper_bound(x[i], 500.0)
    end

    # Não há níveis iniciais não-nulos no GAMS para este modelo.
    if set_starts
        for i in 1:9
            set_start_value(x[i], 0.0)
        end
        set_start_value(objvar, 0.0)
    end

    # Restrições
    @constraint(model, e1, -9.0*x[1] - 15.0*x[2] + 6.0*x[3] + 16.0*x[4] + 10.0*x[5] + 10.0*x[6] - objvar == 0.0)
    @constraint(model, e2, -x[3] - x[4] + x[8] + x[9] == 0.0)
    @constraint(model, e3, x[1] - x[5] - x[8] == 0.0)
    @constraint(model, e4, x[2] - x[6] - x[9] == 0.0)
    @constraint(model, e5, x[7]*x[8] - 2.5*x[1] + 2.0*x[5] <= 0.0)
    @constraint(model, e6, x[7]*x[9] - 1.5*x[2] + 2.0*x[6] <= 0.0)
    @constraint(model, e7, x[7]*x[8] + x[7]*x[9] - 3.0*x[3] - x[4] == 0.0)

    @objective(model, Min, objvar)

    return model, x, objvar
end

model, x, objvar = build_ex5_2_2_case2_model()

# Aliases escalares, para facilitar value(x1), value(x2), etc.
x1 = x[1]
x2 = x[2]
x3 = x[3]
x4 = x[4]
x5 = x[5]
x6 = x[6]
x7 = x[7]
x8 = x[8]
x9 = x[9]

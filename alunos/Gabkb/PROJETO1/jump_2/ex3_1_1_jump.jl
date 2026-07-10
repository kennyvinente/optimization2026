# ex3_1_1_jump.jl
# Modelo JuMP convertido de GAMS Convert NLP
# Fonte: ex3_1_1

using JuMP

function build_ex3_1_1_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, 100.0 <= x1 <= 10000.0)
    @variable(model, 1000.0 <= x2 <= 10000.0)
    @variable(model, 1000.0 <= x3 <= 10000.0)
    @variable(model, 10.0 <= x4 <= 1000.0)
    @variable(model, 10.0 <= x5 <= 1000.0)
    @variable(model, 10.0 <= x6 <= 1000.0)
    @variable(model, 10.0 <= x7 <= 1000.0)
    @variable(model, 10.0 <= x8 <= 1000.0)
    @variable(model, objvar)

    # e1.. - x1 - x2 - x3 + objvar =E= 0
    @constraint(model, e1, -x1 - x2 - x3 + objvar == 0.0)

    # Desigualdades no sentido original do GAMS (=L=)
    @constraint(model, e2, 0.0025 * x4 + 0.0025 * x6 <= 1.0)
    @constraint(model, e3, -0.0025 * x4 + 0.0025 * x5 + 0.0025 * x7 <= 1.0)
    @constraint(model, e4, -0.01 * x5 + 0.01 * x8 <= 1.0)
    @constraint(model, e5, 100.0 * x1 - x1 * x6 + 833.33252 * x4 <= 83333.333)
    @constraint(model, e6, x2 * x4 - x2 * x7 - 1250.0 * x4 + 1250.0 * x5 <= 0.0)
    @constraint(model, e7, x3 * x5 - x3 * x8 - 2500.0 * x5 <= -1250000.0)

    @objective(model, Min, objvar)

    if set_starts
        set_start_value(x1, 579.19)
        set_start_value(x2, 1360.13)
        set_start_value(x3, 5109.92)
        set_start_value(x4, 182.01)
        set_start_value(x5, 295.6)
        set_start_value(x6, 217.99)
        set_start_value(x7, 286.4)
        set_start_value(x8, 395.6)
        set_start_value(objvar, 579.19 + 1360.13 + 5109.92)
    end

    return model, (x1=x1, x2=x2, x3=x3, x4=x4, x5=x5, x6=x6, x7=x7, x8=x8), objvar
end

model, x, objvar = build_ex3_1_1_model()

# Aliases escalares para manter uso parecido com os arquivos GAMS/JuMP anteriores.
x1 = x.x1
x2 = x.x2
x3 = x.x3
x4 = x.x4
x5 = x.x5
x6 = x.x6
x7 = x.x7
x8 = x.x8

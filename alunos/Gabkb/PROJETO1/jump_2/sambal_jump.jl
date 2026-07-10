# sambal_jump_2.jl
# Modelo convertido de GAMS Convert para JuMP/Ipopt

using JuMP
using Ipopt

function build_model(; optimizer = Ipopt.Optimizer)
    model = Model(optimizer)

    @variable(model, x[1:17])
    @variable(model, objvar)

    # Chutes iniciais do GAMS
    set_start_value(x[1], 15.0)
    set_start_value(x[2], 3.0)
    set_start_value(x[3], 130.0)
    set_start_value(x[4], 80.0)
    set_start_value(x[7], 15.0)
    set_start_value(x[8], 130.0)
    set_start_value(x[9], 20.0)
    set_start_value(x[10], 25.0)
    set_start_value(x[11], 40.0)
    set_start_value(x[12], 55.0)
    set_start_value(x[13], 220.0)
    set_start_value(x[16], 190.0)
    set_start_value(x[17], 105.0)

    # Restrições lineares
    @constraint(model, -x[1] - x[2] - x[3] - x[4] + x[13] == 0)
    @constraint(model, -x[5] + x[14] == 0)
    @constraint(model, -x[6] + x[15] == 0)
    @constraint(model, -x[7] - x[8] - x[9] + x[16] == 0)
    @constraint(model, -x[10] - x[11] - x[12] + x[17] == 0)
    @constraint(model, -x[5] - x[6] + x[13] == 0)
    @constraint(model, -x[1] - x[7] - x[10] + x[14] == 0)
    @constraint(model, -x[2] - x[8] - x[11] + x[15] == 0)
    @constraint(model, -x[3] - x[12] + x[16] == 0)
    @constraint(model, -x[4] - x[9] + x[17] == 0)

    # Equação do objetivo no formato GAMS:
    # -(...) + objvar = 0
    @NLconstraint(model,
        -(
            0.0666666666666667 * (15 - x[1])^2 +
            0.333333333333333  * (3  - x[2])^2 +
            0.00769230769230769 * (130 - x[3])^2 +
            0.0125              * (80  - x[4])^2 +
            0.0666666666666667 * (15 - x[7])^2 +
            0.00769230769230769 * (130 - x[8])^2 +
            0.05                * (20  - x[9])^2 +
            0.04                * (25  - x[10])^2 +
            0.025               * (40  - x[11])^2 +
            0.0181818181818182  * (55  - x[12])^2 +
            0.00454545454545455 * (220 - x[13])^2 +
            0.00526315789473684 * (190 - x[16])^2 +
            0.00952380952380952 * (105 - x[17])^2
        ) + objvar == 0
    )

    @objective(model, Min, objvar)

    return model
end

function main()
    model = build_model()

    # Ajustes básicos do Ipopt; o runner externo pode sobrescrever se quiser.
    set_optimizer_attribute(model, "print_level", 5)
    set_optimizer_attribute(model, "tol", 1e-8)

    optimize!(model)

    println("termination_status = ", termination_status(model))
    println("primal_status      = ", primal_status(model))
    println("objective_value    = ", objective_value(model))

    for i in 1:17
        println("x", i, " = ", value(model[:x][i]))
    end
    println("objvar = ", value(model[:objvar]))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

# Modelo JuMP convertido a partir do DAG enviado.
# Convenção:
# - O DAG usa variáveis V 0..29.
# - Aqui elas foram convertidas para x[1]..x[30].
# - O modelo é criado sem solver por padrão, para você poder usar Ipopt, MadNLP, KNITRO etc.

using JuMP
import MathOptInterface as MOI

function build_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:30])

    for i in 1:30
        set_name(x[i], "x$(i)")
    end

    # Bounds/fixações vindas do DAG:
    # <0> b [387.899999999999977,387.899999999999977]: V 0
    # <1> b [85.2999999999999972,85.2999999999999972]: V 8
    fix(x[1], 387.899999999999977; force = true)
    fix(x[9], 85.2999999999999972; force = true)

    # Centros e coeficientes dos termos quadráticos do objetivo.
    # Cada termo tem a forma:
    #     0.5 * (a*x - b) * (x - c)

    a1 = [
        0.0625,
        0.0625,
        0.0625,
        0.0625,
        0.0625,
        0.0625,
        0.0625,
        6.25,
    ]

    b1 = [
        24.2437499999999986,
        24.4255781250000013,
        24.6087699609375008,
        24.7933357356445008,
        24.9792857536619017,
        25.1666303968142984,
        25.3553801247904005,
        2554.55454757263988,
    ]

    c1 = [
        387.899999999999977,
        390.80925000000002,
        393.740319375000013,
        396.693371770312979,
        399.668572058589973,
        402.666086349029001,
        405.686081996646976,
        408.728727611621991,
    ]

    a2 = [
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        100.0,
    ]

    b2 = [
        85.2999999999999972,
        85.9397500000000036,
        86.5842981250000037,
        87.2336803609374982,
        87.8879329636445021,
        88.5470924608718946,
        89.2111956543284066,
        8988.02796217358991,
    ]

    c2 = [
        85.2999999999999972,
        85.9397500000000036,
        86.5842981250000037,
        87.2336803609374982,
        87.8879329636445021,
        88.5470924608718946,
        89.2111956543284066,
        89.8802796217358946,
    ]

    a3 = ones(7)

    b3 = [
        110.5,
        111.328749999999999,
        112.163715624999995,
        113.004943492188005,
        113.852480568378994,
        114.706374172642001,
        115.566671978936995,
    ]

    c3 = copy(b3)

    a4 = fill(0.444000000000000006, 7)

    b4 = [
        65.3123999999999967,
        65.8022430000000043,
        66.2957598225000027,
        66.7929780211688069,
        67.2939253563275059,
        67.7986297964999949,
        68.3071195199737957,
    ]

    c4 = [
        147.099999999999994,
        148.203249999999997,
        149.314774375000013,
        150.434635182812997,
        151.562894946683997,
        152.699616658784009,
        153.844863783725003,
    ]

    # Chute inicial simples, usando os centros dos quadráticos.
    start = vcat(c1, c2, c3, c4)

    for i in 1:30
        set_start_value(x[i], start[i])
    end

    @objective(
        model,
        Min,
        sum(0.5 * (a1[i] * x[i] - b1[i]) * (x[i] - c1[i]) for i in 1:8) +
        sum(0.5 * (a2[i] * x[i + 8] - b2[i]) * (x[i + 8] - c2[i]) for i in 1:8) +
        sum(0.5 * (a3[i] * x[i + 16] - b3[i]) * (x[i + 16] - c3[i]) for i in 1:7) +
        sum(0.5 * (a4[i] * x[i + 23] - b4[i]) * (x[i + 23] - c4[i]) for i in 1:7)
    )

    # Restrições e2..e8:
    # -0.914*x[i] + x[i+1] + 0.016*x[i+8] - 0.305*x[i+16] - 0.424*x[i+23] == -59.4
    cons_e2_e8 = @constraint(
        model,
        [i in 1:7],
        -0.914000000000000035 * x[i] +
        x[i + 1] +
        0.0160000000000000003 * x[i + 8] -
        0.304999999999999993 * x[i + 16] -
        0.423999999999999988 * x[i + 23] ==
        -59.3999999999999986
    )

    for i in 1:7
        set_name(cons_e2_e8[i], "e$(i + 1)")
    end

    # Restrições e9..e15:
    # -0.097*x[i] - 0.424*x[i+8] + x[i+9] + 0.101*x[i+16] - 1.459*x[i+23] == -184.7
    cons_e9_e15 = @constraint(
        model,
        [i in 1:7],
        -0.0970000000000000029 * x[i] -
        0.423999999999999988 * x[i + 8] +
        x[i + 9] +
        0.101000000000000006 * x[i + 16] -
        1.45900000000000007 * x[i + 23] ==
        -184.699999999999989
    )

    for i in 1:7
        set_name(cons_e9_e15[i], "e$(i + 8)")
    end

    return model, x
end

# Compatível com seu padrão de scripts:
# include("modelo_dag_convertido_jump.jl")
# set_optimizer(model, Ipopt.Optimizer)
# optimize!(model)
model, x = build_model()

if abspath(PROGRAM_FILE) == @__FILE__
    try
        @eval using Ipopt

        set_optimizer(model, Ipopt.Optimizer)
        set_optimizer_attribute(model, "print_level", 5)
        set_optimizer_attribute(model, "max_iter", 3000)
        set_optimizer_attribute(model, "tol", 1e-7)
        set_optimizer_attribute(model, "acceptable_tol", 1e-6)

        optimize!(model)

        println("termination_status = ", termination_status(model))
        println("primal_status      = ", primal_status(model))

        if primal_status(model) == MOI.FEASIBLE_POINT
            println("objective_value    = ", objective_value(model))
            for i in 1:30
                println("x[$i] = ", value(x[i]))
            end
        end
    catch err
        @warn "Não consegui rodar standalone. O modelo foi convertido, mas confira se Ipopt está instalado." exception = (err, catch_backtrace())
    end
end

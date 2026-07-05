using JuMP
using Ipopt
using MadNLP

function solve_lukvle2(optimizer)

    n = 100

    model = Model(optimizer)

    @variable(model, 0.6 <= x[1:n+2] <= 1.0)

    for i in 1:n+2
        set_start_value(x[i], 0.8)
    end

    @objective(model, Min,

        sum(

            exp(
                x[i] *
                x[i+1] *
                x[i+2] *
                x[i+3] *
                x[i+4]
            )

            -

            0.5 * sqrt(
                x[i]^3 +
                x[i+1]^3 +
                1.0
            )

            for i in 1:n-2

        )

    )

    optimize!(model)

    println()
    println("====================")
    println("STATUS:")
    println(termination_status(model))

    println()
    println("OBJECTIVE:")
    println(objective_value(model))

end

println()
println("======== IPOPT ========")

solve_lukvle2(Ipopt.Optimizer)

println()
println("======== MADNLP ========")

solve_lukvle2(MadNLP.Optimizer)
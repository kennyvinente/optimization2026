using JuMP
using Ipopt
using MadNLP

function solve_lukvle5(optimizer)

    n = 100

    model = Model(optimizer)

    @variable(model, x[0:n+1])

    for i in 0:n+1
        if 0 < i < n+1
            set_start_value(x[i], -1.0)
        else
            set_start_value(x[i], 0.0)
        end
    end

    @objective(model, Min,

        sum(

            abs(
                (3 - 2*x[i])*x[i]
                - x[i-1]
                - x[i+1]
                + 1
            )^(7/3)

            for i in 1:n

        )

    )

    @constraint(model,

        [i in 1:n-4],

        8*x[i+2]*(x[i+2]^2 - x[i+1])

        -

        2*(1 - x[i+2])

        +

        4*(x[i+2] - x[i+3]^2)

        +

        x[i+1]^2

        -

        x[i]

        +

        x[i+3]

        -

        x[i+4]^2

        == 0

    )

    @constraint(model, x[0] == 0)

    @constraint(model, x[n+1] == 0)

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

solve_lukvle5(Ipopt.Optimizer)

println()
println("======== MADNLP ========")

solve_lukvle5(MadNLP.Optimizer)
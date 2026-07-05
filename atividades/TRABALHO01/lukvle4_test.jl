using JuMP
using Ipopt
using MadNLP

function solve_lukvle5(optimizer)

    n = 100

    model = Model(optimizer)

    @variable(model, x[1:n+2])

    for i in 1:n+2
        if mod(i,4) == 1
            set_start_value(x[i], 1.0)
        else
            set_start_value(x[i], 2.0)
        end
    end

    @objective(model, Min,

        sum(

            (exp(x[2*i-1]) - x[2*i])^4

            +

            100 * (x[2*i] - x[2*i+1])^6

            +

            tan(x[2*i+1] - x[2*i+2])^4

            +

            x[2*i-1]^8

            +

            (x[2*i+2] - 1)^2

            for i in 1:Int(n÷2)

        )

    )

    @constraint(model,

        [i in 1:n-2],

        8*x[i+1]*(x[i+1]^2 - x[i])

        -

        2*(1 - x[i+1])

        +

        4*(x[i+1] - x[i+2]^2)

        == 0

    )

    @constraint(model, x[n+1] == 0)

    @constraint(model, x[n+2] == 0)

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
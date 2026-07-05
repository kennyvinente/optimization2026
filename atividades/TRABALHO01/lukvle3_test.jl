using JuMP
using Ipopt
using MadNLP

function solve_lukvle3(optimizer)

    n = 100

    model = Model(optimizer)

    @variable(model, x[1:n+2])

    for i in 1:n+2

        if mod(i,4) == 1
            set_start_value(x[i], 3.0)

        elseif mod(i,4) == 2
            set_start_value(x[i], -1.0)

        elseif mod(i,4) == 3
            set_start_value(x[i], 0.0)

        else
            set_start_value(x[i], 1.0)

        end

    end

    @objective(model, Min,

        sum(

            (x[2*i-1] + 10*x[2*i])^2

            +

            5*(x[2*i+1] - x[2*i+2])^2

            +

            (x[2*i] - 2*x[2*i+1])^4

            +

            10*(x[2*i-1] - x[2*i+2])^4

            for i in 1:Int(n÷2)

        )

    )

    @constraint(model,

        3*x[1]^3
        +
        2*x[2]
        -
        5
        +
        sin(x[1]-x[2])*sin(x[1]+x[2])
        == 0

    )

    @constraint(model,

        4*x[n]
        -
        x[n-1]*exp(x[n-1]-x[n])
        -
        3
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

solve_lukvle3(Ipopt.Optimizer)

println()
println("======== MADNLP ========")

solve_lukvle3(MadNLP.Optimizer)
using JuMP
using HiGHS
using JSON
using Printf

function solve_machine(path; time_limit=60.0)
    data = JSON.parsefile(path)

    n = data["n"]
    jobs = data["jobs"]
    r = data["release"]
    p = data["duration"]
    d = data["due"]

    H = maximum(r) + sum(p)

    model = Model(HiGHS.Optimizer)
    set_silent(model)
    set_optimizer_attribute(model, "time_limit", time_limit)

    @variable(model, 0 <= s[1:n] <= H)
    @variable(model, 0 <= C[1:n] <= H)
    @variable(model, 0 <= T[1:n] <= H)
    @variable(model, x[1:n, 1:n], Bin)

    for j in 1:n
        @constraint(model, s[j] >= r[j])
        @constraint(model, C[j] == s[j] + p[j])
        @constraint(model, T[j] >= C[j] - d[j])
        @constraint(model, T[j] >= 0)
    end

    for i in 1:n
        for j in 1:n
            if i < j
                @constraint(model, s[i] + p[i] <= s[j] + H * (1 - x[i,j]))
                @constraint(model, s[j] + p[j] <= s[i] + H * x[i,j])
            end
        end
    end

    @objective(model, Min, sum(T[j] for j in 1:n))
    optimize!(model)

    return (
        name = data["name"],
        n = n,
        obj = has_values(model) ? objective_value(model) : NaN,
        status = termination_status(model),
        gap = try relative_gap(model) catch; NaN end
    )
end

function main()
    trabalho_dir = normpath(joinpath(@__DIR__, ".."))
    inst_dir = joinpath(trabalho_dir, "machinescheduling_instances")

    if !isdir(inst_dir)
        println("ERRO: pasta nao encontrada: $inst_dir")
        println("Copie machinescheduling_instances para ATIVIDADES/TRABALHO02/")
        return
    end

    files = sort(filter(f -> endswith(f, ".json"), readdir(inst_dir; join=true)))

    rows = []
    println("Resultados - Machine Scheduling")
    println(@sprintf("%-15s %5s %12s %10s %s", "instancia", "n", "obj", "gap", "status"))

    for file in files
        sol = solve_machine(file; time_limit=60.0)
        obj = isnan(sol.obj) ? "NA" : string(round(sol.obj; digits=2))
        gap = isnan(sol.gap) ? "NA" : string(round(sol.gap; digits=4))

        println(@sprintf("%-15s %5d %12s %10s %s",
                         sol.name, sol.n, obj, gap, string(sol.status)))

        push!(rows, (sol.name, sol.n, obj, gap, string(sol.status)))
    end

    out = joinpath(trabalho_dir, "resultados", "resultados_machine_scheduling.csv")
    mkpath(dirname(out))

    open(out, "w") do io
        println(io, "problema,instancia,n,objetivo_sum_Tj,gap,status")
        for r in rows
            println(io, "Machine Scheduling,$(r[1]),$(r[2]),$(r[3]),$(r[4]),$(r[5])")
        end
    end

    println("\nArquivo salvo em: $out")
end

main()
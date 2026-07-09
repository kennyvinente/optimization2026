using JuMP
using HiGHS
using Printf

function read_fssp(path::String)
    rows = Vector{Vector{Int}}()

    for linha in readlines(path)
        linha = strip(linha)
        isempty(linha) && continue

        partes = split(linha, ",")
        nums = Int[]

        for item in partes
            item = strip(item)

            # pega apenas valores numéricos, ignora J1, M1, cabeçalho etc.
            if occursin(r"^-?\d+$", item)
                push!(nums, parse(Int, item))
            end
        end

        if !isempty(nums)
            push!(rows, nums)
        end
    end

    return reduce(vcat, [reshape(r, 1, length(r)) for r in rows])
end
function solve_flow_shop(path::String; time_limit=60.0)
    p = read_fssp(path)
    n, m = size(p)
    H = sum(p)

    model = Model(HiGHS.Optimizer)
    set_silent(model)
    set_optimizer_attribute(model, "time_limit", time_limit)

    @variable(model, 0 <= S[1:n, 1:m] <= H)
    @variable(model, 0 <= Cmax <= H)
    @variable(model, x[1:n, 1:n], Bin)

    for j in 1:n
        for k in 2:m
            @constraint(model, S[j,k] >= S[j,k-1] + p[j,k-1])
        end
        @constraint(model, Cmax >= S[j,m] + p[j,m])
    end

    for i in 1:n
        for j in 1:n
            if i < j
                @constraint(model, x[i,j] + x[j,i] == 1)
                for k in 1:m
                    @constraint(model, S[i,k] + p[i,k] <= S[j,k] + H * (1 - x[i,j]))
                    @constraint(model, S[j,k] + p[j,k] <= S[i,k] + H * (1 - x[j,i]))
                end
            end
        end
    end

    @objective(model, Min, Cmax)
    optimize!(model)

    return (
        instancia = splitext(basename(path))[1],
        n = n,
        m = m,
        makespan = has_values(model) ? objective_value(model) : NaN,
        gap = try relative_gap(model) catch; NaN end,
        status = termination_status(model)
    )
end

function main()
    trabalho_dir = normpath(joinpath(@__DIR__, ".."))
    inst_dir = joinpath(trabalho_dir, "fssp_problems")

    println("Resultados - Flow Shop Scheduling")
    println(@sprintf("%-18s %5s %5s %12s %10s %s",
                     "instancia", "jobs", "maq", "makespan", "gap", "status"))

    files = sort(filter(f -> endswith(f, ".csv"), readdir(inst_dir; join=true)))
    rows = []

    for file in files
        sol = solve_flow_shop(file; time_limit=60.0)
        makespan = isnan(sol.makespan) ? "NA" : string(round(Int, sol.makespan))
        gap = isnan(sol.gap) ? "NA" : string(round(sol.gap; digits=4))

        println(@sprintf("%-18s %5d %5d %12s %10s %s",
                         sol.instancia, sol.n, sol.m, makespan, gap, string(sol.status)))

        push!(rows, sol)
    end

    out = joinpath(trabalho_dir, "resultados", "resultados_flow_shop.csv")
    mkpath(dirname(out))

    open(out, "w") do io
        println(io, "problema,instancia,n_jobs,n_machines,makespan,gap,status")
        for r in rows
            makespan = isnan(r.makespan) ? "NA" : string(round(Int, r.makespan))
            gap = isnan(r.gap) ? "NA" : string(round(r.gap; digits=4))
            println(io, "Flow Shop Scheduling,$(r.instancia),$(r.n),$(r.m),$makespan,$gap,$(r.status)")
        end
    end

    println("\nArquivo salvo em: $out")
end

main()
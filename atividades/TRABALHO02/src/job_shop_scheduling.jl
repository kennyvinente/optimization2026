# Job Shop Scheduling (JSP) com JSPLIB
# Script adaptado para Julia + JuMP + HiGHS
# Trabalho 02 - Otimizacao

using JuMP
using HiGHS
using JSON
using Printf

const SOLVER = HiGHS.Optimizer

# ------------------------------------------------------------
# Leitura de instancias JSPLIB
# Formato esperado:
# n_jobs n_machines
# maquina duracao maquina duracao ...
# ------------------------------------------------------------
function parse_jsp(path::String)
    lines = [strip(l) for l in eachline(path)
             if !isempty(strip(l)) && !startswith(strip(l), "#")]

    n, m = parse.(Int, split(lines[1]))
    jobs = Vector{Vector{Tuple{Int,Int}}}()

    for jl in lines[2:1+n]
        nums = parse.(Int, split(jl))
        ops = [(nums[i], nums[i + 1]) for i in 1:2:length(nums)]
        push!(jobs, ops)
    end

    return n, m, jobs
end

function instance_meta(metapath::String, name::String)
    if !isfile(metapath)
        return nothing
    end
    for e in JSON.parsefile(metapath)
        if e["name"] == name
            return e
        end
    end
    return nothing
end

# ------------------------------------------------------------
# Modelo disjuntivo MILP para JSP
# Objetivo: minimizar Cmax, isto e, o makespan.
# ------------------------------------------------------------
function solve_jsp(path::String; time_limit::Float64 = 60.0, silent::Bool = true)
    n, m, jobs = parse_jsp(path)

    OPS = [(j, k) for j in 1:n for k in 1:length(jobs[j])]
    mu  = Dict((j, k) => jobs[j][k][1] for (j, k) in OPS)  # maquina 0-based
    p   = Dict((j, k) => jobs[j][k][2] for (j, k) in OPS)
    H   = sum(values(p))

    # Pares de operacoes que disputam a mesma maquina
    bymachine = Dict{Int,Vector{Tuple{Int,Int}}}()
    for o in OPS
        push!(get!(bymachine, mu[o], Tuple{Int,Int}[]), o)
    end

    DP = Tuple{Tuple{Int,Int},Tuple{Int,Int}}[]
    for ops in values(bymachine)
        for a in 1:length(ops)
            for b in (a + 1):length(ops)
                push!(DP, (ops[a], ops[b]))
            end
        end
    end

    model = Model(SOLVER)
    if silent
        set_silent(model)
    end
    set_optimizer_attribute(model, "time_limit", time_limit)

    @variable(model, 0 <= s[OPS] <= H)
    @variable(model, 0 <= Cmax <= H)
    @variable(model, x[1:length(DP)], Bin)

    # Precedencia dentro de cada job
    for j in 1:n
        for k in 1:(length(jobs[j]) - 1)
            @constraint(model, s[(j, k + 1)] >= s[(j, k)] + p[(j, k)])
        end
        last = length(jobs[j])
        @constraint(model, Cmax >= s[(j, last)] + p[(j, last)])
    end

    # Restricoes disjuntivas: duas operacoes na mesma maquina nao podem sobrepor
    for (idx, (o1, o2)) in enumerate(DP)
        @constraint(model, s[o1] + p[o1] <= s[o2] + H * (1 - x[idx]))
        @constraint(model, s[o2] + p[o2] <= s[o1] + H * x[idx])
    end

    @objective(model, Min, Cmax)
    optimize!(model)

    cmax_value = has_values(model) ? objective_value(model) : NaN
    gap_value = try
        relative_gap(model)
    catch
        NaN
    end

    start_times = has_values(model) ? Dict(o => value(s[o]) for o in OPS) : Dict{Tuple{Int,Int},Float64}()

    return (; n, m, jobs, mu, p, OPS, model,
            cmax = cmax_value,
            status = termination_status(model),
            gap = gap_value,
            nbin = length(DP),
            start = start_times)
end

# ------------------------------------------------------------
# Salvar resultados em CSV sem depender do pacote CSV.jl
# ------------------------------------------------------------
function salvar_resultados_csv(rows, outfile::String)
    mkpath(dirname(outfile))
    open(outfile, "w") do io
        println(io, "problema,instancia,n_jobs,n_machines,otimo_conhecido,makespan,gap,n_binarias,status")
        for r in rows
            println(io, join([
                "Job Shop Scheduling",
                r.instancia,
                r.n,
                r.m,
                r.otimo,
                r.makespan,
                r.gap,
                r.nbin,
                r.status
            ], ","))
        end
    end
end

# ------------------------------------------------------------
# Execucao principal
# Ajuste JSPDIR se sua pasta estiver em outro local.
# Estrutura esperada:
# ATIVIDADES/TRABALHO02/jsplib_subset/instances/ft06
# ATIVIDADES/TRABALHO02/jsplib_subset/instances.json
# ------------------------------------------------------------
function main()
    trabalho_dir = normpath(joinpath(@__DIR__, ".."))
    JSPDIR = joinpath(trabalho_dir, "jsplib_subset")
    INSTDIR = joinpath(JSPDIR, "instances")
    METAPATH = joinpath(JSPDIR, "instances.json")

    if !isdir(INSTDIR)
        println("ERRO: pasta de instancias nao encontrada:")
        println(INSTDIR)
        println("\nColoque as instancias em:")
        println("ATIVIDADES/TRABALHO02/jsplib_subset/instances")
        return
    end

    testset = ["ft06", "la01", "la02", "ft10"]
    rows = []

    println("Resultados - Job Shop Scheduling")
    println(@sprintf("%-8s %6s %10s %10s %10s %10s %s", "inst", "n x m", "otimo", "obtido", "gap", "#bin", "status"))

    for name in testset
        path = joinpath(INSTDIR, name)
        if !isfile(path)
            println("Aviso: instancia nao encontrada: $name")
            continue
        end

        meta = instance_meta(METAPATH, name)
        optimo = meta === nothing ? "NA" : string(meta["optimum"])

        sol = solve_jsp(path; time_limit = 60.0, silent = true)
        makespan = isnan(sol.cmax) ? "NA" : string(round(Int, sol.cmax))
        gap = isnan(sol.gap) ? "NA" : string(round(sol.gap; digits = 4))
        status = string(sol.status)

        println(@sprintf("%-8s %3d x %-2d %10s %10s %10s %10d %s",
                         name, sol.n, sol.m, optimo, makespan, gap, sol.nbin, status))

        push!(rows, (instancia = name,
                     n = sol.n,
                     m = sol.m,
                     otimo = optimo,
                     makespan = makespan,
                     gap = gap,
                     nbin = sol.nbin,
                     status = status))
    end

    outfile = joinpath(trabalho_dir, "resultados", "resultados_job_shop.csv")
    salvar_resultados_csv(rows, outfile)
    println("\nArquivo salvo em: $outfile")
end

main()

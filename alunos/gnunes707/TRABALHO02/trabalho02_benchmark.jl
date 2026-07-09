# Trabalho 02 - Otimizacao
# Analise computacional de problemas de escalonamento
# Aluno: Gabriel Nunes da Silva - Matricula: 2250798
# UFAM - PPGEE
#
# Dependencias Julia: JuMP, HiGHS, CSV, DataFrames, JSON, MathOptInterface
# Para instalar uma vez:
# import Pkg; Pkg.add(["JuMP", "HiGHS", "CSV", "DataFrames", "JSON"])

using JuMP
using HiGHS
using CSV
using DataFrames
using JSON
using Dates
import MathOptInterface as MOI

const TIME_LIMIT = parse(Float64, get(ENV, "TIME_LIMIT", "2.0"))
const MIP_REL_GAP = parse(Float64, get(ENV, "MIP_REL_GAP", "0.01"))
const RUN_ALL = get(ENV, "RUN_ALL", "0") == "1"
const MAX_ITER = parse(Int, get(ENV, "MAX_ITER", "200"))

const ROOT = normpath(joinpath(@__DIR__, ".."))
const DATA_DIR = normpath(joinpath(ROOT, "data"))
const OUT_DIR = normpath(joinpath(ROOT, "resultados"))
mkpath(OUT_DIR)

function make_model(; time_limit = TIME_LIMIT, mip_rel_gap = MIP_REL_GAP)
    model = Model(HiGHS.Optimizer)
    set_silent(model)
    set_optimizer_attribute(model, "time_limit", time_limit)
    set_optimizer_attribute(model, "mip_rel_gap", mip_rel_gap)
    if MAX_ITER > 0
        # HiGHS utiliza limites distintos para simplex, IPM e busca MIP.
        # O parametro MAX_ITER e mapeado para esses limites de forma conservadora.
        set_optimizer_attribute(model, "simplex_iteration_limit", MAX_ITER)
        set_optimizer_attribute(model, "ipm_iteration_limit", MAX_ITER)
        set_optimizer_attribute(model, "mip_max_nodes", MAX_ITER)
    end
    return model
end

function safe_gap(model)
    try
        return relative_gap(model)
    catch
        return missing
    end
end

function safe_bound(model)
    try
        return objective_bound(model)
    catch
        return missing
    end
end

function safe_obj(model)
    try
        if has_values(model)
            return objective_value(model)
        else
            return missing
        end
    catch
        return missing
    end
end

function safe_nodes(model)
    try
        return MOI.get(model, MOI.NodeCount())
    catch
        return missing
    end
end

function status_name(model)
    return string(termination_status(model))
end

# -------------------------------------------------------------------------
# 1. Machine Scheduling - uma maquina, datas de liberacao e atraso total
# Problema: 1 | r_j | sum T_j
# -------------------------------------------------------------------------

function read_machine_instance(path::String)
    d = JSON.parsefile(path)
    jobs = String.(d["jobs"])
    release = Dict(jobs .=> Int.(d["release"]))
    duration = Dict(jobs .=> Int.(d["duration"]))
    due = Dict(jobs .=> Int.(d["due"]))
    name = String(d["name"])
    return name, jobs, release, duration, due
end

function solve_machine(path::String; time_limit = TIME_LIMIT, mip_rel_gap = MIP_REL_GAP)
    name, JOBS, rel, dur, due = read_machine_instance(path)
    n = length(JOBS)
    H = maximum(values(rel)) + sum(values(dur))
    M = H + maximum(values(dur))
    PAIRS = [(JOBS[a], JOBS[b]) for a in 1:n for b in a+1:n]

    model = make_model(time_limit = time_limit, mip_rel_gap = mip_rel_gap)
    @variable(model, 0 <= start[JOBS] <= H)
    @variable(model, 0 <= finish[JOBS] <= H)
    @variable(model, 0 <= past[JOBS] <= H)
    @variable(model, z[PAIRS], Bin)

    @constraint(model, [j in JOBS], finish[j] == start[j] + dur[j])
    @constraint(model, [j in JOBS], start[j] >= rel[j])
    @constraint(model, [j in JOBS], past[j] >= finish[j] - due[j])

    for (i, j) in PAIRS
        @constraint(model, start[i] + dur[i] <= start[j] + M * (1 - z[(i, j)]))
        @constraint(model, start[j] + dur[j] <= start[i] + M * z[(i, j)])
    end

    @objective(model, Min, sum(past[j] for j in JOBS))
    elapsed = @elapsed optimize!(model)

    return (
        problem = "Machine Scheduling",
        instance = name,
        n = n,
        m = missing,
        objective = safe_obj(model),
        status = status_name(model),
        gap = safe_gap(model),
        dual_bound = safe_bound(model),
        nodes = safe_nodes(model),
        time = elapsed,
        time_limit = time_limit,
        mip_rel_gap_setting = mip_rel_gap,
    )
end

# -------------------------------------------------------------------------
# 2. Job Shop Scheduling - JSPLIB
# -------------------------------------------------------------------------

function parse_jsp(path::String)
    lines = String[]
    for line in eachline(path)
        s = strip(line)
        if isempty(s) || startswith(s, "#")
            continue
        end
        push!(lines, s)
    end
    nm = parse.(Int, split(lines[1]))
    n, m = nm[1], nm[2]
    jobs = Vector{Vector{Tuple{Int, Int}}}()
    for j in 1:n
        vals = parse.(Int, split(lines[1 + j]))
        ops = Tuple{Int, Int}[]
        for k in 1:m
            # O arquivo JSPLIB usa maquinas 0..m-1; soma-se 1 para indexar em Julia.
            machine = vals[2k - 1] + 1
            duration = vals[2k]
            push!(ops, (machine, duration))
        end
        push!(jobs, ops)
    end
    return n, m, jobs
end

function solve_jsp(path::String; time_limit = TIME_LIMIT, mip_rel_gap = MIP_REL_GAP)
    name = splitext(basename(path))[1]
    n, m, jobs = parse_jsp(path)
    OPS = [(j, k) for j in 1:n for k in 1:length(jobs[j])]
    mach = Dict((j, k) => jobs[j][k][1] for (j, k) in OPS)
    proc = Dict((j, k) => jobs[j][k][2] for (j, k) in OPS)
    H = sum(values(proc))
    M = H

    bymachine = Dict{Int, Vector{Tuple{Int, Int}}}()
    for o in OPS
        push!(get!(bymachine, mach[o], Tuple{Int, Int}[]), o)
    end

    DISJ = Tuple{Tuple{Int, Int}, Tuple{Int, Int}}[]
    for ops in values(bymachine)
        for a in 1:length(ops), b in a+1:length(ops)
            push!(DISJ, (ops[a], ops[b]))
        end
    end

    model = make_model(time_limit = time_limit, mip_rel_gap = mip_rel_gap)
    @variable(model, 0 <= start[OPS] <= H)
    @variable(model, 0 <= Cmax <= H)
    @variable(model, y[1:length(DISJ)], Bin)

    # Precedencia dentro de cada job.
    for j in 1:n
        for k in 1:(length(jobs[j]) - 1)
            @constraint(model, start[(j, k + 1)] >= start[(j, k)] + proc[(j, k)])
        end
        lastk = length(jobs[j])
        @constraint(model, Cmax >= start[(j, lastk)] + proc[(j, lastk)])
    end

    # Disjuncao para operacoes que utilizam a mesma maquina.
    for q in 1:length(DISJ)
        a, b = DISJ[q]
        @constraint(model, start[a] + proc[a] <= start[b] + M * (1 - y[q]))
        @constraint(model, start[b] + proc[b] <= start[a] + M * y[q])
    end

    @objective(model, Min, Cmax)
    elapsed = @elapsed optimize!(model)

    return (
        problem = "Job Shop",
        instance = name,
        n = n,
        m = m,
        objective = safe_obj(model),
        status = status_name(model),
        gap = safe_gap(model),
        dual_bound = safe_bound(model),
        nodes = safe_nodes(model),
        time = elapsed,
        time_limit = time_limit,
        mip_rel_gap_setting = mip_rel_gap,
    )
end

# -------------------------------------------------------------------------
# 3. Flow Shop Scheduling - formulacao posicional
# -------------------------------------------------------------------------

function read_fssp(path::String)
    df = CSV.read(path, DataFrame)
    names = String.(df[:, 1])
    P = Matrix{Int}(df[:, 2:ncol(df)])
    return names, P
end

function solve_fssp(path::String; time_limit = TIME_LIMIT, mip_rel_gap = MIP_REL_GAP)
    name = splitext(basename(path))[1]
    job_names, P = read_fssp(path)
    n, m = size(P)
    H = sum(P)

    model = make_model(time_limit = time_limit, mip_rel_gap = mip_rel_gap)
    @variable(model, x[1:n, 1:n], Bin)    # x[j,k] = job j ocupa posicao k
    @variable(model, 0 <= C[1:n, 1:m] <= H)

    @constraint(model, [j in 1:n], sum(x[j, k] for k in 1:n) == 1)
    @constraint(model, [k in 1:n], sum(x[j, k] for j in 1:n) == 1)

    proc_at(k, i) = sum(P[j, i] * x[j, k] for j in 1:n)

    @constraint(model, C[1, 1] >= proc_at(1, 1))
    for k in 2:n
        @constraint(model, C[k, 1] >= C[k - 1, 1] + proc_at(k, 1))
    end
    for i in 2:m
        @constraint(model, C[1, i] >= C[1, i - 1] + proc_at(1, i))
    end
    for k in 2:n, i in 2:m
        @constraint(model, C[k, i] >= C[k - 1, i] + proc_at(k, i))
        @constraint(model, C[k, i] >= C[k, i - 1] + proc_at(k, i))
    end

    @objective(model, Min, C[n, m])
    elapsed = @elapsed optimize!(model)

    return (
        problem = "Flow Shop",
        instance = name,
        n = n,
        m = m,
        objective = safe_obj(model),
        status = status_name(model),
        gap = safe_gap(model),
        dual_bound = safe_bound(model),
        nodes = safe_nodes(model),
        time = elapsed,
        time_limit = time_limit,
        mip_rel_gap_setting = mip_rel_gap,
    )
end

function selected_instances()
    machine_names = [
        "inst_book", "inst_n05_s01", "inst_n07_s01", "inst_n09_s01",
        "inst_n11_s01", "inst_n13_s01", "inst_n15_s01",
    ]
    jsp_names = ["ft06", "la01", "la02", "la03", "la04", "orb01"]
    fssp_files = sort(filter(f -> endswith(f, ".csv"), readdir(joinpath(DATA_DIR, "fssp_problems"))))

    machine_paths = [joinpath(DATA_DIR, "machinescheduling_instances", name * ".json") for name in machine_names]
    jsp_paths = [joinpath(DATA_DIR, "jsplib_subset", "instances", name) for name in jsp_names]
    fssp_paths = [joinpath(DATA_DIR, "fssp_problems", file) for file in fssp_files]
    return machine_paths, jsp_paths, fssp_paths
end

function all_instances()
    machine_paths = sort(filter(f -> endswith(f, ".json") && basename(f) != "_index.csv",
        [joinpath(DATA_DIR, "machinescheduling_instances", f) for f in readdir(joinpath(DATA_DIR, "machinescheduling_instances"))]))
    jsp_paths = sort([joinpath(DATA_DIR, "jsplib_subset", "instances", f) for f in readdir(joinpath(DATA_DIR, "jsplib_subset", "instances"))])
    fssp_paths = sort(filter(f -> endswith(f, ".csv"), [joinpath(DATA_DIR, "fssp_problems", f) for f in readdir(joinpath(DATA_DIR, "fssp_problems"))]))
    return machine_paths, jsp_paths, fssp_paths
end

function run_benchmark()
    machine_paths, jsp_paths, fssp_paths = RUN_ALL ? all_instances() : selected_instances()
    results = NamedTuple[]

    println("Configuracao: TIME_LIMIT=$(TIME_LIMIT), MIP_REL_GAP=$(MIP_REL_GAP), RUN_ALL=$(RUN_ALL), MAX_ITER=$(MAX_ITER)")
    println("Machine Scheduling: $(length(machine_paths)) instancias")
    for path in machine_paths
        println("  -> ", basename(path))
        push!(results, solve_machine(path))
    end

    println("Job Shop: $(length(jsp_paths)) instancias")
    for path in jsp_paths
        println("  -> ", basename(path))
        push!(results, solve_jsp(path))
    end

    println("Flow Shop: $(length(fssp_paths)) instancias")
    for path in fssp_paths
        println("  -> ", basename(path))
        push!(results, solve_fssp(path))
    end

    df = DataFrame(results)
    out = joinpath(OUT_DIR, "resultados_benchmark_julia.csv")
    CSV.write(out, df)
    println("Resultados salvos em: ", out)
    return df
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_benchmark()
end

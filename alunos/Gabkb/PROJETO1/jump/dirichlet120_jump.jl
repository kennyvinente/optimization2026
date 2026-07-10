using JuMP

# ============================================================
# dirichlet120_jump.jl
# Tradução manual/estruturada do arquivo dirichlet120.mod para JuMP
# ============================================================

function read_scalar_param(mod_path::String, pname::String)
    pat = "param " * pname * " :="

    for line in eachline(mod_path)
        l = strip(line)

        if startswith(l, pat)
            rhs = replace(l, ";" => "")
            rhs = split(rhs, ":=")[2]
            return parse(Float64, strip(rhs))
        end
    end

    error("Parâmetro escalar não encontrado: " * pname)
end

function read_table_param(mod_path::String, marker::String, ncols::Int)
    rows = Int[]
    data = Vector{Vector{Float64}}()

    inside = false

    for line in eachline(mod_path)
        l = strip(line)

        if startswith(l, marker)
            inside = true
            continue
        end

        if inside
            if l == ";"
                break
            end

            if isempty(l)
                continue
            end

            parts = split(l)

            if length(parts) >= ncols + 1
                push!(rows, parse(Int, parts[1]))
                vals = [parse(Float64, parts[k]) for k in 2:(ncols+1)]
                push!(data, vals)
            end
        end
    end

    if isempty(rows)
        error("Tabela não encontrada ou vazia: " * marker)
    end

    nrows = maximum(rows)
    mat = zeros(Float64, nrows, ncols)

    for k in eachindex(rows)
        r = rows[k]
        for c in 1:ncols
            mat[r,c] = data[k][c]
        end
    end

    return mat
end

function read_int_table_param(mod_path::String, marker::String, ncols::Int)
    rows = Int[]
    data = Vector{Vector{Int}}()

    inside = false

    for line in eachline(mod_path)
        l = strip(line)

        if startswith(l, marker)
            inside = true
            continue
        end

        if inside
            if l == ";"
                break
            end

            if isempty(l)
                continue
            end

            parts = split(l)

            if length(parts) >= ncols + 1
                push!(rows, parse(Int, parts[1]))
                vals = [parse(Int, parts[k]) for k in 2:(ncols+1)]
                push!(data, vals)
            end
        end
    end

    if isempty(rows)
        error("Tabela inteira não encontrada ou vazia: " * marker)
    end

    nrows = maximum(rows)
    mat = zeros(Int, nrows, ncols)

    for k in eachindex(rows)
        r = rows[k]
        for c in 1:ncols
            mat[r,c] = data[k][c]
        end
    end

    return mat
end

function read_vector_param(mod_path::String, marker::String)
    idxs = Int[]
    vals = Float64[]

    inside = false

    for line in eachline(mod_path)
        l = strip(line)

        if startswith(l, marker)
            inside = true
            continue
        end

        if inside
            if l == ";"
                break
            end

            if isempty(l)
                continue
            end

            parts = split(l)

            if length(parts) >= 2
                push!(idxs, parse(Int, parts[1]))
                push!(vals, parse(Float64, parts[2]))
            end
        end
    end

    if isempty(idxs)
        error("Vetor não encontrado ou vazio: " * marker)
    end

    v = zeros(Float64, maximum(idxs))

    for k in eachindex(idxs)
        v[idxs[k]] = vals[k]
    end

    return v
end

# ------------------------------------------------------------
# Localiza o .mod
# ------------------------------------------------------------

mod_path = joinpath(@__DIR__, "..", "dirichlet120.mod")

if !isfile(mod_path)
    mod_path = "dirichlet120.mod"
end

if !isfile(mod_path)
    error("Arquivo dirichlet120.mod não encontrado.")
end

println("Lendo dados de: ", mod_path)

# ------------------------------------------------------------
# Dados do .mod
# ------------------------------------------------------------

NODES = Int(read_scalar_param(mod_path, "NODES"))
ELEMS = Int(read_scalar_param(mod_path, "ELEMS"))

DIMEN = 2
BREAK = 120

D = 1:DIMEN
N = 1:NODES
E = 1:ELEMS

COORDS = read_table_param(mod_path, "param COORDS:", 2)
TRIANG = read_int_table_param(mod_path, "param TRIANG:", 3)

BNDRY_float = read_vector_param(mod_path, "param BNDRY :=")
BNDRY = [BNDRY_float[i] > 0.5 for i in 1:length(BNDRY_float)]

US = read_vector_param(mod_path, "param US :=")
UE = read_vector_param(mod_path, "param UE :=")

ALPHA = read_scalar_param(mod_path, "ALPHA")

# Parâmetros definidos por let no final do arquivo
a = 0.01
b = ones(Float64, NODES)
c = ones(Float64, NODES)
d = zeros(Float64, NODES)
p = fill(3.0, NODES)

# ------------------------------------------------------------
# Quantidades derivadas
# ------------------------------------------------------------

EDGE = zeros(Float64, ELEMS, DIMEN + 1, DIMEN)

for e in E
    for d1 in 1:(DIMEN + 1)
        for d2 in D
            n_next = TRIANG[e, mod(d1, DIMEN + 1) + 1]
            n_curr = TRIANG[e, d1]
            EDGE[e,d1,d2] = COORDS[n_next,d2] - COORDS[n_curr,d2]
        end
    end
end

AREA = zeros(Float64, ELEMS)

for e in E
    AREA[e] = (
        EDGE[e,1,1] * EDGE[e,2,2] -
        EDGE[e,1,2] * EDGE[e,2,1]
    ) / 2.0
end

H = ALPHA / (BREAK + 1) * sqrt(sum((US[n] - UE[n])^2 for n in N))

println("NODES = ", NODES)
println("ELEMS = ", ELEMS)
println("BREAK = ", BREAK)
println("H = ", H)

# ------------------------------------------------------------
# Modelo
# ------------------------------------------------------------

model = Model()

@variable(model, u[0:BREAK+1, N])
@variable(model, z)

# ------------------------------------------------------------
# Valores iniciais
# Caminho linear entre US e UE
# ------------------------------------------------------------

for b1 in 0:(BREAK + 1)
    for n in N
        valor = (1.0 - b1/(BREAK + 1)) * US[n] + (b1/(BREAK + 1)) * UE[n]
        set_start_value(u[b1,n], valor)
    end
end

set_start_value(z, 0.0)

# ------------------------------------------------------------
# Expressões de energia por elemento e por ponto da trajetória
# ------------------------------------------------------------

@NLexpression(
    model,
    integral[b1 in 0:BREAK+1, e1 in E],
    AREA[e1] * (
        1.0 / (DIMEN + 1) *
        sum(
            b[TRIANG[e1,c1]] * u[b1,TRIANG[e1,c1]]^2 / 2.0
            -
            c[TRIANG[e1,c1]] * u[b1,TRIANG[e1,c1]]^(p[TRIANG[e1,c1]] + 1.0) /
            (p[TRIANG[e1,c1]] + 1.0)
            +
            d[TRIANG[e1,c1]] * u[b1,TRIANG[e1,c1]]
            for c1 in 1:(DIMEN + 1)
        )
        +
        a / (8.0 * AREA[e1]^2) * (
            u[b1,TRIANG[e1,1]]^2 * (EDGE[e1,2,1]^2 + EDGE[e1,2,2]^2)
            +
            u[b1,TRIANG[e1,2]]^2 * (EDGE[e1,3,1]^2 + EDGE[e1,3,2]^2)
            +
            u[b1,TRIANG[e1,3]]^2 * (EDGE[e1,1,1]^2 + EDGE[e1,1,2]^2)
            +
            2.0 * u[b1,TRIANG[e1,1]] * u[b1,TRIANG[e1,2]] *
            (EDGE[e1,2,1] * EDGE[e1,3,1] + EDGE[e1,2,2] * EDGE[e1,3,2])
            +
            2.0 * u[b1,TRIANG[e1,1]] * u[b1,TRIANG[e1,3]] *
            (EDGE[e1,2,1] * EDGE[e1,1,1] + EDGE[e1,2,2] * EDGE[e1,1,2])
            +
            2.0 * u[b1,TRIANG[e1,2]] * u[b1,TRIANG[e1,3]] *
            (EDGE[e1,1,1] * EDGE[e1,3,1] + EDGE[e1,1,2] * EDGE[e1,3,2])
        )
    )
)

@NLexpression(
    model,
    energy[b1 in 0:BREAK+1],
    sum(integral[b1,e1] for e1 in E)
)

# ------------------------------------------------------------
# Objetivo
# ------------------------------------------------------------

@objective(model, Min, z)

# ------------------------------------------------------------
# Restrições
# ------------------------------------------------------------

@NLconstraint(
    model,
    max_energy[b1 in 1:BREAK],
    z >= energy[b1]
)

@NLconstraint(
    model,
    distance[b1 in 0:BREAK],
    sum((u[b1+1,n] - u[b1,n])^2 for n in N) <= H^2
)

@constraint(
    model,
    boundary[b1 in 1:BREAK, n in N; BNDRY[n]],
    u[b1,n] == 0.0
)

@constraint(
    model,
    start[n in N],
    u[0,n] == US[n]
)

@constraint(
    model,
    finish[n in N],
    u[BREAK+1,n] == UE[n]
)

println("Modelo dirichlet120 carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

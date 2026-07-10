using JuMP
using Random

# ============================================================
# NARX_CFy_jump.jl
# Tradução manual/estruturada do arquivo NARX_CFy.mod para JuMP
# ============================================================

function clean_line(line::AbstractString)
    return strip(split(String(line), "#")[1])
end

function read_vector_param(mod_path::String, marker::String)
    idxs = Int[]
    vals = Float64[]

    inside = false

    for line in eachline(mod_path)
        l = clean_line(line)

        if isempty(l)
            continue
        end

        if startswith(l, marker)
            inside = true
            continue
        end

        if inside
            if l == ";"
                break
            end

            parts = split(l)

            if length(parts) >= 2
                push!(idxs, parse(Int, parts[1]))
                push!(vals, parse(Float64, parts[2]))
            end
        end
    end

    if isempty(idxs)
        error("Parâmetro não encontrado ou vazio: " * marker)
    end

    v = zeros(Float64, maximum(idxs))

    for k in eachindex(idxs)
        v[idxs[k]] = vals[k]
    end

    return v
end

function read_scalar_param(mod_path::String, pname::String)
    pat = "param " * pname

    for line in eachline(mod_path)
        l = clean_line(line)

        if startswith(l, pat) && occursin(":=", l)
            rhs = replace(l, ";" => "")
            rhs = split(rhs, ":=")[2]
            return parse(Float64, strip(rhs))
        end
    end

    error("Parâmetro escalar não encontrado: " * pname)
end

# ------------------------------------------------------------
# Localiza o arquivo .mod
# ------------------------------------------------------------

mod_path = joinpath(@__DIR__, "..", "NARX_CFy.mod")

if !isfile(mod_path)
    mod_path = "NARX_CFy.mod"
end

if !isfile(mod_path)
    error("Arquivo NARX_CFy.mod não encontrado.")
end

println("Lendo dados de: ", mod_path)

# ------------------------------------------------------------
# Dados principais
# ------------------------------------------------------------

N = Int(read_scalar_param(mod_path, "N"))
Nu = Int(read_scalar_param(mod_path, "Nu"))

a1 = read_vector_param(mod_path, "param a1 :=")
a2 = read_vector_param(mod_path, "param a2 :=")

nn1 = Int.(round.(read_vector_param(mod_path, "param nn1 :=")))
nn2 = Int.(round.(read_vector_param(mod_path, "param nn2 :=")))

theta1 = read_vector_param(mod_path, "param theta1 :=")
theta2 = read_vector_param(mod_path, "param theta2 :=")

ny11 = nn1[1]
ny22 = nn2[1]

nu11 = nn1[2]
nu22 = nn2[2]

ny1 = nn1[3]
ny2 = nn2[3]

nu1 = nn1[4]
nu2 = nn2[4]

td1 = nn1[5]
td2 = nn2[5]

mo = maximum([
    ny11,
    ny22,
    td1 + nu11,
    td2 + nu22,
    ny1,
    ny2,
    td1 + nu1,
    td2 + nu2
]) + 1

mx = 1e-2
my = 8e-3

pn = Dict(i => i * 2.0 * pi / N for i in 0:N-1)

# ------------------------------------------------------------
# Índices ind[0..14]
# ------------------------------------------------------------

ind = Dict{Int,Int}()

ind[0]  = 1
ind[1]  = ny11
ind[2]  = ny22
ind[3]  = nu11 + 1
ind[4]  = nu22 + 1
ind[5]  = div(ny1 * (ny1 + 1), 2)
ind[6]  = div(ny2 * (ny2 + 1), 2)
ind[7]  = div((nu1 + 1) * (nu1 + 2), 2)
ind[8]  = div((nu2 + 1) * (nu2 + 2), 2)
ind[9]  = ny1 * (nu1 + 1)
ind[10] = ny1 * (nu2 + 1)
ind[11] = ny2 * (nu1 + 1)
ind[12] = ny2 * (nu2 + 1)
ind[13] = ny1 * ny2
ind[14] = (nu1 + 1) * (nu2 + 1)

offset = Dict{Int,Int}()
offset[0] = 0

for kk in 1:14
    offset[kk] = offset[kk-1] + ind[kk-1]
end

maxind = maximum(values(ind))

println("N = ", N)
println("Nu = ", Nu)
println("mo = ", mo)
println("maxind = ", maxind)
println("sum(ind) = ", sum(values(ind)))

# ------------------------------------------------------------
# Modelo
# ------------------------------------------------------------

model = Model()

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, alpha[1:Nu, 1:2])
@variable(model, phi[0:14, 0:2*N-1, 1:maxind])
@variable(model, x[-mo:2*N-1, 1:2])
@variable(model, y[-mo:2*N-1, 1:2])
@variable(model, t)

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

Random.seed!(1234)

for u in 1:Nu
    for j in 1:2
        set_start_value(alpha[u,j], -pi + 2*pi*rand())
    end
end

for kk in 0:14
    for i in 0:2*N-1
        for l in 1:maxind
            if kk == 0
                set_start_value(phi[kk,i,l], 1.0)
            else
                set_start_value(phi[kk,i,l], 0.0)
            end
        end
    end
end

for i in -mo:2*N-1
    for j in 1:2
        set_start_value(x[i,j], 0.0)

        if i >= 0
            set_start_value(y[i,j], 0.01)
        else
            set_start_value(y[i,j], 0.0)
        end
    end
end

set_start_value(t, 0.01)

# ------------------------------------------------------------
# Objetivo
# ------------------------------------------------------------

@objective(model, Min, t)

# ------------------------------------------------------------
# Restrições de limite para y no intervalo N..2N-1
# ------------------------------------------------------------

@constraint(model, bound31[j in N:2*N-1], -t <= y[j,1])
@constraint(model, bound32[j in N:2*N-1],  y[j,1] <= t)

@constraint(model, bound41[j in N:2*N-1], -t <= y[j,2])
@constraint(model, bound42[j in N:2*N-1],  y[j,2] <= t)

# ------------------------------------------------------------
# Inicialização de x, y e phi
# ------------------------------------------------------------

@constraint(model, xstart[i in -mo:-1, j in 1:2], x[i,j] == 0.0)
@constraint(model, ystart[i in -mo:-1, j in 1:2], y[i,j] == 0.0)

@constraint(model, pstart[i in 0:2*N-1, j in 1:4], phi[0,i,j] == 1.0)

# ------------------------------------------------------------
# Entrada x
# ------------------------------------------------------------

@NLconstraint(
    model,
    inp1_ch1[i in 0:N-1],
    x[i,1] == sum(a1[u] * cos(pn[i] * u + alpha[u,1]) for u in 1:Nu)
)

@NLconstraint(
    model,
    inp1_ch2[i in 0:N-1],
    x[i,2] == sum(a2[u] * cos(pn[i] * u + alpha[u,2]) for u in 1:Nu)
)

@constraint(
    model,
    inp2[i in N:2*N-1, j in 1:2],
    x[i,j] == x[i-N,j]
)

# ------------------------------------------------------------
# Regressores lineares
# ------------------------------------------------------------

@constraint(
    model,
    p1[i in 0:2*N-1, j in 1:ny11],
    phi[1,i,j] == y[i-j,1]
)

@constraint(
    model,
    p2[i in 0:2*N-1, j in 1:ny22],
    phi[2,i,j] == y[i-j,2]
)

@constraint(
    model,
    p3[i in 0:2*N-1, j in td1:td1+nu11],
    phi[3,i,j-td1+1] == x[i-j,1]
)

@constraint(
    model,
    p4[i in 0:2*N-1, j in td2:td2+nu22],
    phi[4,i,j-td2+1] == x[i-j,2]
)

# ------------------------------------------------------------
# Regressores quadráticos
# ------------------------------------------------------------

@NLconstraint(
    model,
    p5[i in 0:2*N-1, j in 1:ny1, l in 1:j],
    phi[5,i,div((j-1)*j,2)+l] == y[i-j,1] * y[i-l,1]
)

@NLconstraint(
    model,
    p6[i in 0:2*N-1, j in 1:ny2, l in 1:j],
    phi[6,i,div((j-1)*j,2)+l] == y[i-j,2] * y[i-l,2]
)

@NLconstraint(
    model,
    p7[i in 0:2*N-1, j in td1:td1+nu1, l in td1:j],
    phi[7,i,div((j-td1)*(j-td1+1),2)+l-td1+1] == x[i-j,1] * x[i-l,1]
)

@NLconstraint(
    model,
    p8[i in 0:2*N-1, j in td2:td2+nu2, l in td2:j],
    phi[8,i,div((j-td2)*(j-td2+1),2)+l-td2+1] == x[i-j,2] * x[i-l,2]
)

@NLconstraint(
    model,
    p9[i in 0:2*N-1, j in 1:ny1, l in td1:td1+nu1],
    phi[9,i,(j-1)*(nu1+1)+l-td1+1] == y[i-j,1] * x[i-l,1]
)

@NLconstraint(
    model,
    p10[i in 0:2*N-1, j in 1:ny1, l in td2:td2+nu2],
    phi[10,i,(j-1)*(nu2+1)+l-td2+1] == y[i-j,1] * x[i-l,2]
)

@NLconstraint(
    model,
    p11[i in 0:2*N-1, j in 1:ny2, l in td1:td1+nu1],
    phi[11,i,(j-1)*(nu1+1)+l-td1+1] == y[i-j,2] * x[i-l,1]
)

@NLconstraint(
    model,
    p12[i in 0:2*N-1, j in 1:ny2, l in td2:td2+nu2],
    phi[12,i,(j-1)*(nu2+1)+l-td2+1] == y[i-j,2] * x[i-l,2]
)

@NLconstraint(
    model,
    p13[i in 0:2*N-1, j in 1:ny1, l in 1:ny2],
    phi[13,i,(j-1)*ny2+l] == y[i-j,1] * y[i-l,2]
)

@NLconstraint(
    model,
    p14[i in 0:2*N-1, j in td1:td1+nu1, l in td2:td2+nu2],
    phi[14,i,(j-td1)*(nu2+1)+l-td2+1] == x[i-j,1] * x[i-l,2]
)

# ------------------------------------------------------------
# Saídas NARX
# ------------------------------------------------------------

@NLconstraint(
    model,
    out1[i in 0:2*N-1],
    y[i,1] ==
    sum(
        phi[kk,i,l] * theta1[offset[kk] + l]
        for kk in 0:14 for l in 1:ind[kk]
    )
)

@NLconstraint(
    model,
    out2[i in 0:2*N-1],
    y[i,2] ==
    sum(
        phi[kk,i,l] * theta2[offset[kk] + l]
        for kk in 0:14 for l in 1:ind[kk]
    )
)

# ------------------------------------------------------------
# Restrições de variação em x e y
# ------------------------------------------------------------

@constraint(model, move1[i in 0:N-2, j in 1:2], -mx <= x[i+1,j] - x[i,j])
@constraint(model, move2[j in 1:2], -mx <= x[0,j] - x[N-1,j])

@constraint(model, movey[i in N-1:2*N-2, j in 1:2], -my <= y[i+1,j] - y[i,j])

@constraint(model, move3[i in 0:N-2, j in 1:2], x[i+1,j] - x[i,j] <= mx)
@constraint(model, move4[j in 1:2], x[0,j] - x[N-1,j] <= mx)

@constraint(model, movey1[i in N-1:2*N-2, j in 1:2], y[i+1,j] - y[i,j] <= my)

println("Modelo NARX_CFy carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

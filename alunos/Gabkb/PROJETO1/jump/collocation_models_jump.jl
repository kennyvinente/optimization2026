using JuMP

# ============================================================
# collocation_models_jump.jl
# Gera modelos JuMP para:
# - pinene_3200.mod
# - marine_1600.mod
# ============================================================

function clean_line(line::AbstractString)
    return strip(split(String(line), "#")[1])
end

function read_scalar_param(mod_path::String, pname::String)
    pat = "param " * pname * " :="

    for line in eachline(mod_path)
        l = clean_line(line)

        if startswith(l, pat)
            rhs = replace(l, ";" => "")
            rhs = split(rhs, ":=")[2]
            return parse(Int, strip(rhs))
        end
    end

    error("Parâmetro escalar não encontrado: " * pname)
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

    v = zeros(Float64, maximum(idxs))

    for k in eachindex(idxs)
        v[idxs[k]] = vals[k]
    end

    return v
end

function read_table_param(mod_path::String, marker::String, ncols::Int)
    rows = Int[]
    data = Vector{Vector{Float64}}()
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

            if length(parts) >= ncols + 1
                push!(rows, parse(Int, parts[1]))
                vals = [parse(Float64, parts[k]) for k in 2:(ncols+1)]
                push!(data, vals)
            end
        end
    end

    mat = zeros(Float64, maximum(rows), ncols)

    for k in eachindex(rows)
        r = rows[k]
        for c in 1:ncols
            mat[r,c] = data[k][c]
        end
    end

    return mat
end

function build_pinene_model(mod_path::String)
    nc = read_scalar_param(mod_path, "nc")
    ne = read_scalar_param(mod_path, "ne")
    np = read_scalar_param(mod_path, "np")
    nm = read_scalar_param(mod_path, "nm")
    nh = read_scalar_param(mod_path, "nh")

    tau = read_vector_param(mod_path, "param tau :=")
    rho = read_vector_param(mod_path, "param rho :=")
    bc = read_vector_param(mod_path, "param bc :=")
    z = read_table_param(mod_path, "param z", ne)

    tf = tau[nm]
    h = tf / nh

    tgrid = [(i - 1) * h for i in 1:nh+1]
    fact = [factorial(j) for j in 0:nc]

    itau = [
        min(nh, floor(Int, tau[i] / h) + 1)
        for i in 1:nm
    ]

    model = Model()

    @variable(model, theta[1:np] >= 0.0)
    @variable(model, v[1:nh, 1:ne])
    @variable(model, w[1:nh, 1:nc, 1:ne])

    for i in 1:np
        set_start_value(theta[i], 0.0)
    end

    for i in 1:itau[1], s in 1:ne
        set_start_value(v[i,s], bc[s])
    end

    for j in 2:nm
        for i in itau[j-1]+1:itau[j], s in 1:ne
            set_start_value(v[i,s], z[j,s])
        end
    end

    for i in itau[nm]+1:nh, s in 1:ne
        set_start_value(v[i,s], z[nm,s])
    end

    for i in 1:nh, j in 1:nc, s in 1:ne
        set_start_value(w[i,j,s], 0.0)
    end

    @NLexpression(
        model,
        uc[i in 1:nh, j in 1:nc, s in 1:ne],
        v[i,s] + h * sum(w[i,k,s] * rho[j]^k / fact[k+1] for k in 1:nc)
    )

    @NLexpression(
        model,
        Duc[i in 1:nh, j in 1:nc, s in 1:ne],
        sum(w[i,k,s] * rho[j]^(k-1) / fact[k] for k in 1:nc)
    )

    @NLobjective(
        model,
        Min,
        sum(
            sum(
                (
                    v[itau[j],s]
                    +
                    sum(
                        w[itau[j],k,s] *
                        (tau[j] - tgrid[itau[j]])^k /
                        (fact[k+1] * h^(k-1))
                        for k in 1:nc
                    )
                    -
                    z[j,s]
                )^2
                for s in 1:ne
            )
            for j in 1:nm
        )
    )

    @constraint(model, ode_bc[s in 1:ne], v[1,s] == bc[s])

    @NLconstraint(
        model,
        continuity[i in 1:nh-1, s in 1:ne],
        v[i,s] + h * sum(w[i,j,s] / fact[j+1] for j in 1:nc) == v[i+1,s]
    )

    @NLconstraint(
        model,
        collocation_eqn1[i in 1:nh, j in 1:nc],
        Duc[i,j,1] == -(theta[1] + theta[2]) * uc[i,j,1]
    )

    @NLconstraint(
        model,
        collocation_eqn2[i in 1:nh, j in 1:nc],
        Duc[i,j,2] == theta[1] * uc[i,j,1]
    )

    @NLconstraint(
        model,
        collocation_eqn3[i in 1:nh, j in 1:nc],
        Duc[i,j,3] == theta[2] * uc[i,j,1] - (theta[3] + theta[4]) * uc[i,j,3] + theta[5] * uc[i,j,5]
    )

    @NLconstraint(
        model,
        collocation_eqn4[i in 1:nh, j in 1:nc],
        Duc[i,j,4] == theta[3] * uc[i,j,3]
    )

    @NLconstraint(
        model,
        collocation_eqn5[i in 1:nh, j in 1:nc],
        Duc[i,j,5] == theta[4] * uc[i,j,3] - theta[5] * uc[i,j,5]
    )

    return model
end

function build_marine_model(mod_path::String)
    nc = read_scalar_param(mod_path, "nc")
    ne = read_scalar_param(mod_path, "ne")
    nm = read_scalar_param(mod_path, "nm")
    nh = read_scalar_param(mod_path, "nh")

    tau = read_vector_param(mod_path, "param tau :=")
    rho = read_vector_param(mod_path, "param rho :=")
    z = read_table_param(mod_path, "param z", ne)

    tf = tau[nm]
    h = tf / nh

    tgrid = [(i - 1) * h for i in 1:nh+1]
    fact = [factorial(j) for j in 0:nc]

    itau = [
        min(nh, floor(Int, tau[i] / h) + 1)
        for i in 1:nm
    ]

    model = Model()

    @variable(model, g[1:ne-1] >= 0.0)
    @variable(model, m[1:ne] >= 0.0)
    @variable(model, v[1:nh, 1:ne])
    @variable(model, w[1:nh, 1:nc, 1:ne])

    for s in 1:ne-1
        set_start_value(g[s], 0.0)
    end

    for s in 1:ne
        set_start_value(m[s], 0.0)
    end

    for i in 1:itau[1], s in 1:ne
        set_start_value(v[i,s], z[1,s])
    end

    for j in 2:nm
        for i in itau[j-1]+1:itau[j], s in 1:ne
            set_start_value(v[i,s], z[j,s])
        end
    end

    for i in itau[nm]+1:nh, s in 1:ne
        set_start_value(v[i,s], z[nm,s])
    end

    for i in 1:nh, j in 1:nc, s in 1:ne
        set_start_value(w[i,j,s], 0.0)
    end

    @NLexpression(
        model,
        uc[i in 1:nh, j in 1:nc, s in 1:ne],
        v[i,s] + h * sum(w[i,k,s] * rho[j]^k / fact[k+1] for k in 1:nc)
    )

    @NLexpression(
        model,
        Duc[i in 1:nh, j in 1:nc, s in 1:ne],
        sum(w[i,k,s] * rho[j]^(k-1) / fact[k] for k in 1:nc)
    )

    @NLobjective(
        model,
        Min,
        sum(
            sum(
                (
                    v[itau[j],s]
                    +
                    sum(
                        w[itau[j],k,s] *
                        (tau[j] - tgrid[itau[j]])^k /
                        (fact[k+1] * h^(k-1))
                        for k in 1:nc
                    )
                    -
                    z[j,s]
                )^2
                for s in 1:ne
            )
            for j in 1:nm
        )
    )

    @NLconstraint(
        model,
        continuity[i in 1:nh-1, s in 1:ne],
        v[i,s] + h * sum(w[i,j,s] / fact[j+1] for j in 1:nc) == v[i+1,s]
    )

    @NLconstraint(
        model,
        collocation_eqn1[i in 1:nh, j in 1:nc],
        Duc[i,j,1] == -(m[1] + g[1]) * uc[i,j,1]
    )

    @NLconstraint(
        model,
        collocation_eqns[i in 1:nh, j in 1:nc, s in 2:ne-1],
        Duc[i,j,s] == g[s-1] * uc[i,j,s-1] - (m[s] + g[s]) * uc[i,j,s]
    )

    @NLconstraint(
        model,
        collocation_ne[i in 1:nh, j in 1:nc],
        Duc[i,j,ne] == g[ne-1] * uc[i,j,ne-1] - m[ne] * uc[i,j,ne]
    )

    return model
end

model
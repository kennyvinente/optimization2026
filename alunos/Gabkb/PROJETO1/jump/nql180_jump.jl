using JuMP
using SparseArrays

# ============================================================
# nql180_jump.jl
# Tradução do arquivo nql180.mod para JuMP
#
# Este arquivo lê os dados QPS/AMPL diretamente do .mod
# e monta o modelo em JuMP.
# ============================================================

function _clean_token(s::AbstractString)
    return replace(strip(String(s)), '"' => "")
end

function _add_lin!(lin_by_row, row::String, col::String, val::Float64)
    push!(get!(lin_by_row, row, Tuple{String,Float64}[]), (col, val))
end

function _add_quad!(quad_by_row, row::String, col1::String, col2::String, val::Float64)
    push!(get!(quad_by_row, row, Tuple{String,String,Float64}[]), (col1, col2, val))
end

function _make_expr(row::String, x, lin_by_row, quad_by_row)
    expr = AffExpr(0.0)

    for (j, aij) in get(lin_by_row, row, Tuple{String,Float64}[])
        add_to_expression!(expr, aij, x[j])
    end

    qexpr = QuadExpr(expr)

    for (j, k, hij) in get(quad_by_row, row, Tuple{String,String,Float64}[])
        coef = j == k ? 0.5 * hij : hij
        add_to_expression!(qexpr, coef, x[j], x[k])
    end

    return qexpr
end

function build_nql180_model(mod_path::String)
    if !isfile(mod_path)
        error("Arquivo .mod não encontrado: $mod_path")
    end

    println("Lendo arquivo: ", mod_path)

    lin_by_row = Dict{String, Vector{Tuple{String,Float64}}}()
    quad_by_row = Dict{String, Vector{Tuple{String,String,Float64}}}()

    b = Dict{String, Float64}()
    db = Dict{String, Float64}()
    lb = Dict{String, Float64}()
    ub = Dict{String, Float64}()

    ctype = Dict{String, String}()
    row_order = String[]
    Jset = Set{String}()

    section = :none

    open(mod_path, "r") do io
        for line in eachline(io)
            l = strip(line)

            if isempty(l)
                continue
            end

            if startswith(l, "param :Aij: A :=")
                section = :A
                continue
            elseif startswith(l, "param b :=")
                section = :b
                continue
            elseif startswith(l, "param db :=")
                section = :db
                continue
            elseif startswith(l, "param ub :=")
                section = :ub
                continue
            elseif startswith(l, "param lb :=")
                section = :lb
                continue
            elseif startswith(l, "param :Qc: hc :=")
                section = :Qc
                continue
            elseif startswith(l, "param :Q: h :=")
                section = :Q
                continue
            elseif startswith(l, "param :I1: ctype :=")
                section = :ctype
                continue
            elseif l == ";"
                section = :none
                continue
            end

            parts = split(l)

            if section == :A
                if length(parts) >= 3
                    row = _clean_token(parts[1])
                    col = _clean_token(parts[2])
                    val = parse(Float64, parts[3])

                    _add_lin!(lin_by_row, row, col, val)
                    push!(Jset, col)
                end

            elseif section == :b
                if length(parts) >= 2
                    row = _clean_token(parts[1])
                    val = parse(Float64, parts[2])
                    b[row] = val
                end

            elseif section == :db
                if length(parts) >= 2
                    row = _clean_token(parts[1])
                    val = parse(Float64, parts[2])
                    db[row] = val
                end

            elseif section == :lb
                if length(parts) >= 2
                    col = _clean_token(parts[1])
                    val = parse(Float64, parts[2])
                    lb[col] = val
                    push!(Jset, col)
                end

            elseif section == :ub
                if length(parts) >= 2
                    col = _clean_token(parts[1])
                    val = parse(Float64, parts[2])
                    ub[col] = val
                    push!(Jset, col)
                end

            elseif section == :Qc
                if length(parts) >= 4
                    row = _clean_token(parts[1])
                    col1 = _clean_token(parts[2])
                    col2 = _clean_token(parts[3])
                    val = parse(Float64, parts[4])

                    _add_quad!(quad_by_row, row, col1, col2, val)
                    push!(Jset, col1)
                    push!(Jset, col2)
                end

            elseif section == :Q
                # Caso apareça matriz quadrática global Q.
                # Neste arquivo nql180 normalmente ela não aparece.
                if length(parts) >= 3
                    col1 = _clean_token(parts[1])
                    col2 = _clean_token(parts[2])
                    val = parse(Float64, parts[3])

                    _add_quad!(quad_by_row, "OBJ", col1, col2, val)
                    push!(Jset, col1)
                    push!(Jset, col2)
                end

            elseif section == :ctype
                if length(parts) >= 2
                    row = _clean_token(parts[1])
                    typ = _clean_token(parts[2])

                    ctype[row] = typ
                    push!(row_order, row)
                end
            end
        end
    end

    J = sort(collect(Jset))

    println("Dados carregados.")
    println("Variáveis detectadas: ", length(J))
    println("Linhas detectadas: ", length(row_order))
    println("Linhas com coeficientes lineares: ", length(lin_by_row))
    println("Linhas com coeficientes quadráticos: ", length(quad_by_row))

    model = Model()

    @variable(model, x[J])

    # Limites das variáveis:
    # AMPL:
    # lb default 0
    # ub default Infinity
    # se lb <= -1.7e38, interpreta como -Inf
    for j in J
        lj = get(lb, j, 0.0)
        uj = get(ub, j, Inf)

        if lj > -1.7e38
            set_lower_bound(x[j], lj)
        end

        if isfinite(uj)
            set_upper_bound(x[j], uj)
        end
    end

    # Função objetivo:
    # linha com ctype == "N"
    objective_rows = [r for r in row_order if get(ctype, r, "") == "N"]

    if isempty(objective_rows)
        println("Aviso: nenhuma linha N encontrada. Objetivo zero.")
        @objective(model, Min, 0.0)
    else
        obj_row = objective_rows[1]
        obj_expr = _make_expr(obj_row, x, lin_by_row, quad_by_row)
        @objective(model, Min, obj_expr)
        println("Linha de objetivo: ", obj_row)
    end

    # Restrições
    nE = 0
    nL = 0
    nG = 0
    nLR = 0
    nGR = 0

    for row in row_order
        typ = get(ctype, row, "")

        if typ == "N"
            continue
        end

        expr = _make_expr(row, x, lin_by_row, quad_by_row)
        rhs = get(b, row, 0.0)

        if typ == "E"
            @constraint(model, expr == rhs)
            nE += 1

        elseif typ == "L"
            @constraint(model, expr <= rhs)
            nL += 1

        elseif typ == "G"
            @constraint(model, expr >= rhs)
            nG += 1

        elseif typ == "LR"
            delta = get(db, row, 0.0)
            @constraint(model, rhs - delta <= expr <= rhs)
            nLR += 1

        elseif typ == "GR"
            delta = get(db, row, 0.0)
            @constraint(model, rhs <= expr <= rhs + delta)
            nGR += 1
        end
    end

    println("Modelo nql180 carregado com sucesso.")
    println("Variáveis JuMP: ", num_variables(model))
    println("Restrições E: ", nE)
    println("Restrições L: ", nL)
    println("Restrições G: ", nG)
    println("Restrições LR: ", nLR)
    println("Restrições GR: ", nGR)
    println("Total de restrições JuMP: ", num_constraints(model; count_variable_in_set_constraints = true))

    return model
end

# Caminho padrão:
# O .jl fica em arq_jump, então procuramos o .mod uma pasta acima.
mod_path = joinpath(@__DIR__, "..", "nql180.mod")

if !isfile(mod_path)
    # Alternativa: procurar na pasta atual do notebook
    mod_path = "nql180.mod"
end

model = build_nql180_model(mod_path)

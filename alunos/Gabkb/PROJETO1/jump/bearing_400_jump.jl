using JuMP

# ============================================================
# bearing_400_jump.jl
# Tradução manual do arquivo bearing_400.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros do problema
# ------------------------------------------------------------

nx = 400
ny = 400

b = 10.0
e = 0.1

hx = 2*pi/(nx + 1)
hy = 2*b/(ny + 1)

area = 0.5*hx*hy

# Parâmetro indexado wq[i], com i = 0, ..., nx+1
wq = Dict(
    i => (1 + e*cos(i*hx))^3
    for i in 0:nx+1
)

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, v[0:nx+1, 0:ny+1] >= 0)

# ------------------------------------------------------------
# Valores iniciais
# AMPL:
# let {i in 0..nx+1,j in 0..ny+1} v[i,j] := max(sin(i*hx),0);
# ------------------------------------------------------------

for i in 0:nx+1
    for j in 0:ny+1
        set_start_value(v[i,j], max(sin(i*hx), 0.0))
    end
end

# ------------------------------------------------------------
# Função objetivo
# AMPL:
# minimize q:
#   0.5*(hx*hy/6)*sum {i in 0..nx,j in 0..ny} ...
# + 0.5*(hx*hy/6)*sum {i in 1..nx+1,j in 1..ny+1} ...
# - hx*hy*sum {i in 0..nx+1,j in 0..ny+1} ...
# ------------------------------------------------------------

@objective(
    model,
    Min,
    0.5*(hx*hy/6) *
    sum(
        (wq[i] + 2*wq[i+1]) *
        (
            ((v[i+1,j] - v[i,j])/hx)^2 +
            ((v[i,j+1] - v[i,j])/hy)^2
        )
        for i in 0:nx, j in 0:ny
    )
    +
    0.5*(hx*hy/6) *
    sum(
        (2*wq[i] + 2*wq[i-1]) *
        (
            ((v[i-1,j] - v[i,j])/hx)^2 +
            ((v[i,j-1] - v[i,j])/hy)^2
        )
        for i in 1:nx+1, j in 1:ny+1
    )
    -
    hx*hy *
    sum(
        e*sin(i*hx)*v[i,j]
        for i in 0:nx+1, j in 0:ny+1
    )
)

# ------------------------------------------------------------
# Restrições de contorno
# ------------------------------------------------------------

@constraint(model, c1[i in 0:nx+1], v[i, 0] == 0)
@constraint(model, c2[i in 0:nx+1], v[i, ny+1] == 0)
@constraint(model, c3[j in 0:ny+1], v[0, j] == 0)
@constraint(model, c4[j in 0:ny+1], v[nx+1, j] == 0)

println("Modelo bearing_400 carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

model
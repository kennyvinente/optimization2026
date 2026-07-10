using JuMP

# ============================================================
# camshape_6400_jump.jl
# Tradução manual do arquivo camshape_6400.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

n = 6400

R_v = 1.0
R_min = 1.0
R_max = 2.0
alpha = 1.5

d_theta = 2*pi/(5*(n + 1))

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, R_min <= r[1:n] <= R_max)

# ------------------------------------------------------------
# Valores iniciais
# AMPL:
# let {i in 1..n} r[i] := (R_min + R_max)/2;
# ------------------------------------------------------------

for i in 1:n
    set_start_value(r[i], (R_min + R_max)/2)
end

# ------------------------------------------------------------
# Função objetivo
# AMPL:
# maximize valve_area: ((pi*R_v)/n)*sum {i in 1..n} r[i];
# ------------------------------------------------------------

@objective(
    model,
    Max,
    ((pi * R_v) / n) * sum(r[i] for i in 1:n)
)

# ------------------------------------------------------------
# Restrições de convexidade
# ------------------------------------------------------------

@NLconstraint(
    model,
    convexity[i in 2:n-1],
    -r[i-1]*r[i] - r[i]*r[i+1] + 2*r[i-1]*r[i+1]*cos(d_theta) <= 0
)

@NLconstraint(
    model,
    convex_edge1,
    -R_min*r[1] - r[1]*r[2] + 2*R_min*r[2]*cos(d_theta) <= 0
)

@NLconstraint(
    model,
    convex_edge2,
    -R_min^2 - R_min*r[1] + 2*R_min*r[1]*cos(d_theta) <= 0
)

@NLconstraint(
    model,
    convex_edge3,
    -r[n-1]*r[n] - r[n]*R_max + 2*r[n-1]*R_max*cos(d_theta) <= 0
)

@NLconstraint(
    model,
    convex_edge4,
    -2*R_max*r[n] + 2*r[n]^2*cos(d_theta) <= 0
)

# ------------------------------------------------------------
# Restrições de curvatura
# ------------------------------------------------------------

@constraint(
    model,
    curvature[i in 1:n-1],
    -alpha*d_theta <= r[i+1] - r[i]
)

@constraint(
    model,
    curvature_edge1,
    -alpha*d_theta <= r[1] - R_min
)

@constraint(
    model,
    curvature_edge2,
    -alpha*d_theta <= R_max - r[n]
)

@constraint(
    model,
    curvature1[i in 1:n-1],
    r[i+1] - r[i] <= alpha*d_theta
)

@constraint(
    model,
    curvature_edge11,
    r[1] - R_min <= alpha*d_theta
)

@constraint(
    model,
    curvature_edge21,
    R_max - r[n] <= alpha*d_theta
)

println("Modelo camshape_6400 carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

model

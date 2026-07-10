using JuMP

# ============================================================
# gasoil_3200_jump.jl
# Tradução manual do arquivo gasoil_3200.mod para JuMP
# ============================================================

model = Model()

# ------------------------------------------------------------
# Parâmetros
# ------------------------------------------------------------

nc = 4
ne = 2
np = 3
nm = 21
nh = 3200

rho = Dict(
    1 => 0.06943184420297,
    2 => 0.33000947820757,
    3 => 0.66999052179243,
    4 => 0.93056815579703
)

bc = Dict(
    1 => 1.0,
    2 => 0.0
)

tau = Dict(
     1 => 0.0,
     2 => 0.025,
     3 => 0.05,
     4 => 0.075,
     5 => 0.10,
     6 => 0.125,
     7 => 0.150,
     8 => 0.175,
     9 => 0.20,
    10 => 0.225,
    11 => 0.250,
    12 => 0.30,
    13 => 0.35,
    14 => 0.40,
    15 => 0.45,
    16 => 0.50,
    17 => 0.55,
    18 => 0.65,
    19 => 0.75,
    20 => 0.85,
    21 => 0.95
)

z = Dict(
    (1,1) => 1.0000, (1,2) => 0.0000,
    (2,1) => 0.8105, (2,2) => 0.2000,
    (3,1) => 0.6208, (3,2) => 0.2886,
    (4,1) => 0.5258, (4,2) => 0.3010,
    (5,1) => 0.4345, (5,2) => 0.3215,
    (6,1) => 0.3903, (6,2) => 0.3123,
    (7,1) => 0.3342, (7,2) => 0.2716,
    (8,1) => 0.3034, (8,2) => 0.2551,
    (9,1) => 0.2735, (9,2) => 0.2258,
    (10,1) => 0.2405, (10,2) => 0.1959,
    (11,1) => 0.2283, (11,2) => 0.1789,
    (12,1) => 0.2071, (12,2) => 0.1457,
    (13,1) => 0.1669, (13,2) => 0.1198,
    (14,1) => 0.1530, (14,2) => 0.0909,
    (15,1) => 0.1339, (15,2) => 0.0719,
    (16,1) => 0.1265, (16,2) => 0.0561,
    (17,1) => 0.1200, (17,2) => 0.0460,
    (18,1) => 0.0990, (18,2) => 0.0280,
    (19,1) => 0.0870, (19,2) => 0.0190,
    (20,1) => 0.0770, (20,2) => 0.0140,
    (21,1) => 0.0690, (21,2) => 0.0100
)

tf = tau[nm]
h = tf / nh

tgrid = Dict(i => (i - 1) * h for i in 1:nh+1)

fact = Dict(j => factorial(j) for j in 0:nc)

itau = Dict(
    i => min(nh, floor(Int, tau[i] / h) + 1)
    for i in 1:nm
)

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

@variable(model, theta[1:np] >= 0.0)
@variable(model, v[1:nh, 1:ne])
@variable(model, w[1:nh, 1:nc, 1:ne])

# ------------------------------------------------------------
# Valores iniciais
# ------------------------------------------------------------

for i in 1:np
    set_start_value(theta[i], 0.0)
end

# let {i in 1..itau[1],s in 1..ne} v[i,s] := bc[s];
for i in 1:itau[1]
    for s in 1:ne
        set_start_value(v[i,s], bc[s])
    end
end

# let {j in 2..nm, i in itau[j-1]+1..itau[j], s in 1..ne} v[i,s] := z[j,s];
for j in 2:nm
    ini = itau[j-1] + 1
    fim = itau[j]

    if ini <= fim
        for i in ini:fim
            for s in 1:ne
                set_start_value(v[i,s], z[j,s])
            end
        end
    end
end

# let {i in itau[nm]+1..nh, s in 1..ne} v[i,s] := z[nm,s];
ini_final = itau[nm] + 1

if ini_final <= nh
    for i in ini_final:nh
        for s in 1:ne
            set_start_value(v[i,s], z[nm,s])
        end
    end
end

# let {i in 1..nh, j in 1..nc, s in 1..ne} w[i,j,s] := 0;
for i in 1:nh
    for j in 1:nc
        for s in 1:ne
            set_start_value(w[i,j,s], 0.0)
        end
    end
end

# ------------------------------------------------------------
# Expressões auxiliares
# uc e Duc da formulação de colocação
# ------------------------------------------------------------

@NLexpression(
    model,
    uc[i in 1:nh, j in 1:nc, s in 1:ne],
    v[i,s] + h * sum(
        w[i,k,s] * (rho[j]^k / fact[k])
        for k in 1:nc
    )
)

@NLexpression(
    model,
    Duc[i in 1:nh, j in 1:nc, s in 1:ne],
    sum(
        w[i,k,s] * (rho[j]^(k-1) / fact[k-1])
        for k in 1:nc
    )
)

# ------------------------------------------------------------
# Função objetivo
# ------------------------------------------------------------

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
                    (fact[k] * h^(k-1))
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

# ------------------------------------------------------------
# Restrições
# ------------------------------------------------------------

@constraint(
    model,
    ODE_IC[s in 1:ne],
    v[1,s] == bc[s]
)

@NLconstraint(
    model,
    continuity[i in 1:nh-1, s in 1:ne],
    v[i,s] + sum(w[i,j,s] * h / fact[j] for j in 1:nc) == v[i+1,s]
)

@NLconstraint(
    model,
    collocation_eqn1[i in 1:nh, j in 1:nc],
    Duc[i,j,1] == -(theta[1] + theta[3]) * uc[i,j,1]^2
)

@NLconstraint(
    model,
    collocation_eqn2[i in 1:nh, j in 1:nc],
    Duc[i,j,2] == theta[1] * uc[i,j,1]^2 - theta[2] * uc[i,j,2]
)

println("Modelo gasoil_3200 carregado com sucesso.")
println("Variáveis: ", num_variables(model))
println("Restrições: ", num_constraints(model; count_variable_in_set_constraints = true))

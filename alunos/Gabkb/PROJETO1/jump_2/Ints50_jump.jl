
# Ints50_jump.jl
# Modelo Ints50 convertido de GAMS Convert para JuMP em forma compacta.
# Usa a estrutura de malha trapezoidal do arquivo original.

using JuMP

model = Model()

const N = 50
const THETA = 1:(N + 1)
const XPOS = (N + 2):(2N + 2)
const YPOS = (2N + 3):(3N + 3)
const VX = (3N + 4):(4N + 4)
const VY = (4N + 5):(5N + 5)
const HIDX = 5N + 7
const x_index = vcat(collect(THETA), collect(XPOS), collect(YPOS), collect(VX), collect(VY), [HIDX])

@variable(model, x[x_index])
@variable(model, objvar)

for i in x_index
    @eval const $(Symbol("x", i)) = x[$i]
end

# Ângulos
for i in THETA
    set_lower_bound(x[i], -1.5707963267949)
    set_upper_bound(x[i],  1.5707963267949)
end

# Variáveis positivas declaradas no GAMS
for i in [first(XPOS), first(YPOS), first(VX), first(VY), last(VY), HIDX]
    set_lower_bound(x[i], 0.0)
end

# Fixações de contorno
fix(x[first(XPOS)], 0.0; force=true)
fix(x[first(YPOS)], 0.0; force=true)
fix(x[last(YPOS)], 5.0; force=true)
fix(x[first(VX)], 0.0; force=true)
fix(x[last(VX)], 45.0; force=true)
fix(x[first(VY)], 0.0; force=true)
fix(x[last(VY)], 0.0; force=true)

# Chutes iniciais do GAMS
for k in 2:N
    set_start_value(x[first(YPOS) + k - 1], (5.0 / N) * k)
    set_start_value(x[first(VX) + k - 1], (45.0 / N) * k)
end
set_start_value(x[HIDX], 1.0 / N)

@constraint(model, objvar - N * x[HIDX] == 0)

# Integração trapezoidal do primeiro estado
for k in 1:N
    @constraint(model,
        -0.5*x[HIDX]*(x[first(VX) + k - 1] + x[first(VX) + k])
        - x[first(XPOS) + k - 1] + x[first(XPOS) + k] == 0
    )
end

# Integração trapezoidal do segundo estado
for k in 1:N
    @constraint(model,
        -0.5*x[HIDX]*(x[first(VY) + k - 1] + x[first(VY) + k])
        - x[first(YPOS) + k - 1] + x[first(YPOS) + k] == 0
    )
end

# Dinâmica de velocidade em x
for k in 1:N
    @constraint(model,
        -0.5*x[HIDX]*(100*cos(x[k]) + 100*cos(x[k + 1]))
        - x[first(VX) + k - 1] + x[first(VX) + k] == 0
    )
end

# Dinâmica de velocidade em y
for k in 1:N
    @constraint(model,
        -0.5*x[HIDX]*(100*sin(x[k]) + 100*sin(x[k + 1]))
        - x[first(VY) + k - 1] + x[first(VY) + k] == 0
    )
end

@objective(model, Min, objvar)

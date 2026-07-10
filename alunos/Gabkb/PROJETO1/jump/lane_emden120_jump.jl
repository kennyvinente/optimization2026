using JuMP
using SparseArrays

# Modelo JuMP gerado automaticamente
model = Model()

# Parâmetros do bloco data
# Param ignorado no bloco data: NODES
# Param ignorado no bloco data: COORDS
# Param ignorado no bloco data: BNDRY
# Param ignorado no bloco data: US
# Param ignorado no bloco data: UE
# Param ignorado no bloco data: ELEMS
# Param ignorado no bloco data: TRIANG
# Param ignorado no bloco data: ALPHA
# Param ignorado no bloco data: EBAR
# Param ignorado no bloco data: BBAR
# Param ignorado no bloco data: UBAR

# Parâmetros calculados do bloco model
DIMEN = 2
BREAK = 120

# Atribuições escalares do bloco data
a = 1
EBAR = max{b1 in 0..BREAK+1 : energy[b1] < 0.0} energy[b1]
BBAR = min{b1 in 0..BREAK+1 : energy[b1] = EBAR} b1
z = max{b1 in 0..BREAK+1} energy[b1]

# Sets
D = [nothing for idx1 in 1:(DIMEN)]
N = [nothing for idx1 in 1:(NODES)]
E = [nothing for idx1 in 1:(ELEMS)]

# Parâmetros indexados
EDGE = JuMP.Containers.DenseAxisArray([COORDS[TRIANG[e,(d1 mod (DIMEN+1)) + 1],d2] - COORDS[TRIANG[e,d1],d2] for e in E, d1 in 1:(DIMEN+1), d2 in D], E, 1:(DIMEN+1), D)
AREA = JuMP.Containers.DenseAxisArray([(EDGE[e,1,1]*EDGE[e,2,2] - EDGE[e,1,2]*EDGE[e,2,1]) / 2 for e in E], E)
# Param indexado ignorado: H

# Variáveis
@variable(model, u[0:(BREAK+1), N])
@variable(model, z)
@variable(model, integral[b1 in 0:(BREAK+1), e1 in E])
@variable(model, energy[b1 in 0:(BREAK+1)])

# Valores iniciais
for n in N
    set_start_value(b[n], 0)
end
for n in N
    set_start_value(c[n], 1)
end
for n in N
    set_start_value(d[n], 0)
end
for n in N
    set_start_value(p[n], 3)
end
for b1 in 0:(BREAK+1), n in N
    set_start_value(u[b1,n], (1 - b1/(BREAK+1))*US[n] + (b1/(BREAK+1))*UE[n])
end
for n in N
    set_start_value(UE[n], 2*UE[n])
end
for n in N
    set_start_value(UBAR[n], US[n])
end
for b1 in 0:(BREAK+1), n in N
    set_start_value(u[b1,n], (1 - b1/(BREAK+1))*UBAR[n] + (b1/(BREAK+1))*UE[n])
end
for n in N
    set_start_value(UBAR[n], u[BBAR-1, n])
end
for n in N
    set_start_value(UE[n], u[BBAR, n])
end
for b1 in 0:(BREAK+1), n in N
    set_start_value(u[b1,n], (1 - b1/(BREAK+1))*US[n] + (b1/(BREAK+1))*UE[n])
end

# Objetivo
@NLobjective(model, Min, z)

# Restrições
# max_energy
for b1 in 1:(BREAK)
    @NLconstraint(model, z >= energy[b1])
end

# distance
for b1 in 0:(BREAK)
    @NLconstraint(model, sum((u[b1+1,n]-u[b1,n]) for n in N)^2 <= H^2)
end

# boundary
for b1 in 1:(BREAK), n in N
    @NLconstraint(model, u[b1,n] == 0)
end

# start
for n in N
    @NLconstraint(model, u[0,n] == US[n])
end

# end
for n in N
    @NLconstraint(model, u[BREAK+1,n] == UE[n])
end


# Para resolver:
# using Ipopt
# set_optimizer(model, Ipopt.Optimizer)
# optimize!(model)
# println("Status: ", termination_status(model))
# println("Objetivo: ", objective_value(model))

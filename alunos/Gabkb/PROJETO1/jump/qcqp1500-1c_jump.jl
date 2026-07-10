using JuMP
using SparseArrays

# Modelo JuMP gerado automaticamente
model = Model()

# Parâmetros do bloco data
# Param ignorado no bloco data: n
# Param ignorado no bloco data: ml
# Param ignorado no bloco data: mq
# Param ignorado no bloco data: pl
# Param ignorado no bloco data: pq
# Param ignorado no bloco data: sd
# Param ignorado no bloco data: sq
# Param ignorado no bloco data: sp
# Param ignorado no bloco data: plf
# Param ignorado no bloco data: pqf

# Parâmetros calculados do bloco model

# Atribuições escalares do bloco data

# Sets

# Parâmetros indexados
LQ = JuMP.Containers.DenseAxisArray([((i === j) ? (Uniform01()) : (if Uniform01() < sq then Uniform(-10,10))) for i in 1:(n), j in 1:(i)], 1:(n), 1:(i))
Q = JuMP.Containers.DenseAxisArray([((sd === 1) ? (sum((LQ[i,k]*LQ[j,k]) : (if i) for k in 1:(min(i,j)))>= j then LQ[i,j] else LQ[j,i])) for i in 1:(n), j in 1:(n)], 1:(n), 1:(n))
LP = JuMP.Containers.DenseAxisArray([((i === j) ? (Uniform01()) : (if Uniform01() < sp then Uniform(-10,10))) for l in 1:(mq+pq), i in 1:(n), j in 1:(i)], 1:(mq+pq), 1:(n), 1:(i))
P = JuMP.Containers.DenseAxisArray([sum((LP[l,i,k]*LP[l,j,k]) for k in 1:(min(i,j))) for l in 1:(mq+pq), i in 1:(n), j in 1:(n)], 1:(mq+pq), 1:(n), 1:(n))
y = JuMP.Containers.DenseAxisArray([Normal01() for i in 1:(ml+mq)], 1:(ml+mq))
z = JuMP.Containers.DenseAxisArray([((i<= pl && Uniform01() < plf) ? (Uniform(0,10)) : (if i> pl && Uniform01() < pqf then Uniform(0,10))) for i in 1:(pl+pq)], 1:(pl+pq))
A0 = JuMP.Containers.DenseAxisArray([Normal01() for i in 1:(ml+mq+pl+pq), j in 1:(n)], 1:(ml+mq+pl+pq), 1:(n))
A = JuMP.Containers.DenseAxisArray([((abs(A0[i,j]) === max{k in 1..n} abs(A0[i,k])) ? (A0[i,j]) : (if Uniform01() < sq then A0[i,j])) for i in 1:(ml+mq+pl+pq), j in 1:(n)], 1:(ml+mq+pl+pq), 1:(n))
xstar = JuMP.Containers.DenseAxisArray([Normal01() for i in 1:(n)], 1:(n))
g = JuMP.Containers.DenseAxisArray([sum((y[j]*A[j,i]) for j in 1:(ml))+ sum((y[j]*A[j,i]) for j in ml+1:(ml+mq))+ sum((y[j]*P[j-ml,i,k]*xstar[k]) for j in ml+1:(ml+mq), k in 1:(n))+ sum((z[j-ml-mq]*A[j,i]) for j in ml+mq+1:(ml+mq+pl))+ sum((z[j-ml-mq]*A[j,i]) for j in ml+mq+pl+1:(ml+mq+pl+pq))+sum((z[j-ml-mq]*P[j-ml-pl,i,k]*xstar[k]) for j in ml+mq+pl+1:(ml+mq+pl+pq), k in 1:(n))- sum((Q[i,j]*xstar[j]) for j in 1:(n)) for i in 1:(n)], 1:(n))
b_eq = JuMP.Containers.DenseAxisArray([sum((A[i,j]*xstar[j]) for j in 1:(n))+ if i > ml then 0.5* sum((P[i-ml,j,k]*xstar[j]*xstar[k]) for j in 1:(n), k in 1:(n)) for i in 1:(ml+mq)], 1:(ml+mq))
b_ineq = JuMP.Containers.DenseAxisArray([sum((A[ml+mq+i,j]*xstar[j]) for j in 1:(n))+ if i > pl then 0.5* sum((P[mq+i-pl,j,k]*xstar[j]*xstar[k]) for j in 1:(n), k in 1:(n)) for i in 1:(pl+pq)], 1:(pl+pq))

# Variáveis
@variable(model, x[i in 1:(n)])

# Valores iniciais

# Objetivo
@NLobjective(model, Min, 0.5*sum((Q[i,j]*x[i]*x[j]) for i in 1:(n), j in 1:(n))+ sum((g[i]*x[i]) for i in 1:(n)))

# Restrições
# eq
for i in 1:(ml+mq)
    @NLconstraint(model, sum((A[i,j]*x[j]) for j in 1:(n))+ if i > ml then 0.5* sum((P[i-ml,j,k]*x[j]*x[k]) for j in 1:(n), k in 1:(n))=== b_eq[i])
end

# ineq
for i in 1:(pl+pq)
    @NLconstraint(model, sum((A[ml+mq+i,j]*x[j]) for j in 1:(n))+ if i > pl then 0.5* sum((P[mq+i-pl,j,k]*x[j]*x[k]) for j in 1:(n), k in 1:(n))<= b_ineq[i])
end


# Para resolver:
# using Ipopt
# set_optimizer(model, Ipopt.Optimizer)
# optimize!(model)
# println("Status: ", termination_status(model))
# println("Objetivo: ", objective_value(model))

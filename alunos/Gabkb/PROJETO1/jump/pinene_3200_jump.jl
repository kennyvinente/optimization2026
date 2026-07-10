using JuMP
using SparseArrays

# Modelo JuMP gerado automaticamente
model = Model()

# Parâmetros do bloco data
# Param ignorado no bloco data: nc
# Param ignorado no bloco data: ne
# Param ignorado no bloco data: np
# Param ignorado no bloco data: nm
# Param ignorado no bloco data: nh
# Param ignorado no bloco data: tau
z = JuMP.Containers.DenseAxisArray([
    88.35 7.3 2.3 0.4 1.75;
    76.4 15.6 4.5 0.7 2.8;
    65.1 23.1 5.3 1.1 5.8;
    50.4 32.9 6.0 1.5 9.3;
    37.5 42.7 6.0 1.9 12.0;
    25.9 49.1 5.9 2.2 17.0;
    14.0 57.4 5.1 2.6 21.0;
    4.5 63.1 3.8 2.9 25.7;
], [1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5])
# Param ignorado no bloco data: rho
# Param ignorado no bloco data: bc

# Parâmetros calculados do bloco model
tf = tau[nm]
h = tf/nh

# Atribuições escalares do bloco data

# Sets

# Parâmetros indexados
t = JuMP.Containers.DenseAxisArray([(i-1)*h for i in 1:(nh+1)], 1:(nh+1))
fact = JuMP.Containers.DenseAxisArray([((j == 0) ? (1) : ((prod{i in 1..j} i))) for j in 0:(nc)], 0:(nc))
itau = JuMP.Containers.DenseAxisArray([min(nh,floor(tau[i]/h)+1) for i in 1:(nm)], 1:(nm))

# Variáveis
@variable(model, theta[1:(np)])
@variable(model, v[1:(nh), 1:(ne)])
@variable(model, w[1:(nh), 1:(nc), 1:(ne)])
@variable(model, uc[i in 1:(nh), j in 1:(nc), s in 1:(ne)])
@variable(model, Duc[i in 1:(nh), j in 1:(nc), s in 1:(ne)])

# Valores iniciais
for i in 1:(np)
    set_start_value(theta[i], 0.0)
end
for i in 1:(itau[1]), s in 1:(ne)
    set_start_value(v[i,s], bc[s])
end
for j in 2:(nm), i in itau[j-1]+1:(itau[j]), s in 1:(ne)
    set_start_value(v[i,s], z[j,s])
end
for i in itau[nm]+1:(nh), s in 1:(ne)
    set_start_value(v[i,s], z[nm,s])
end
for i in 1:(nh), j in 1:(nc), s in 1:(ne)
    set_start_value(w[i,j,s], 0)
end

# Objetivo
@NLobjective(model, Min, sum((sum((v[itau[j],s] + ( sum((w[itau[j],k,s]*(tau[j]-t[itau[j]])^k/(fact[k]*h^(k-1))) for k in 1:(nc))) - z[j,s]) for s in 1:(ne))^2) for j in 1:(nm)))

# Restrições
# theta_bounds
for i in 1:(np)
    @NLconstraint(model, theta[i] >= 0.0)
end

# ode_bc
for s in 1:(ne)
    @NLconstraint(model, v[1,s] == bc[s])
end

# continuity
for i in 1:(nh-1), s in 1:(ne)
    @NLconstraint(model, v[i,s] + h*sum((w[i,j,s]/fact[j]) for j in 1:(nc)) == v[i+1,s])
end

# collocation_eqn1
for i in 1:(nh), j in 1:(nc)
    @NLconstraint(model, Duc[i,j,1] == - (theta[1]+theta[2])*uc[i,j,1])
end

# collocation_eqn2
for i in 1:(nh), j in 1:(nc)
    @NLconstraint(model, Duc[i,j,2] == theta[1]*uc[i,j,1])
end

# collocation_eqn3
for i in 1:(nh), j in 1:(nc)
    @NLconstraint(model, Duc[i,j,3] == theta[2]*uc[i,j,1] - (theta[3]+theta[4])*uc[i,j,3] + theta[5]*uc[i,j,5])
end

# collocation_eqn4
for i in 1:(nh), j in 1:(nc)
    @NLconstraint(model, Duc[i,j,4] == theta[3]*uc[i,j,3])
end

# collocation_eqn5
for i in 1:(nh), j in 1:(nc)
    @NLconstraint(model, Duc[i,j,5] == theta[4]*uc[i,j,3] - theta[5]*uc[i,j,5])
end


# Para resolver:
# using Ipopt
# set_optimizer(model, Ipopt.Optimizer)
# optimize!(model)
# println("Status: ", termination_status(model))
# println("Objetivo: ", objective_value(model))

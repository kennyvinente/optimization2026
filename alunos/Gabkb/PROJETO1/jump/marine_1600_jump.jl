using JuMP
using SparseArrays

# Modelo JuMP gerado automaticamente
model = Model()

# Parâmetros do bloco data
# Param ignorado no bloco data: nc
# Param ignorado no bloco data: ne
# Param ignorado no bloco data: nm
# Param ignorado no bloco data: nh
# Param ignorado no bloco data: tau
z = JuMP.Containers.DenseAxisArray([
    20000.0 17000.0 10000.0 15000.0 12000.0 9000.0 7000.0 3000.0;
    12445.0 15411.0 13040.0 13338.0 13484.0 8426.0 6615.0 4022.0;
    7705.0 13074.0 14623.0 11976.0 12453.0 9272.0 6891.0 5020.0;
    4664.0 8579.0 12434.0 12603.0 11738.0 9710.0 6821.0 5722.0;
    2977.0 7053.0 11219.0 11340.0 13665.0 8534.0 6242.0 5695.0;
    1769.0 5054.0 10065.0 11232.0 12112.0 9600.0 6647.0 7034.0;
    943.0 3907.0 9473.0 10334.0 11115.0 8826.0 6842.0 7348.0;
    581.0 2624.0 7421.0 10297.0 12427.0 8747.0 7199.0 7684.0;
    355.0 1744.0 5369.0 7748.0 10057.0 8698.0 6542.0 7410.0;
    223.0 1272.0 4713.0 6869.0 9564.0 8766.0 6810.0 6961.0;
    137.0 821.0 3451.0 6050.0 8671.0 8291.0 6827.0 7525.0;
    87.0 577.0 2649.0 5454.0 8430.0 7411.0 6423.0 8388.0;
    49.0 337.0 2058.0 4115.0 7435.0 7627.0 6268.0 7189.0;
    32.0 228.0 1440.0 3790.0 6474.0 6658.0 5859.0 7467.0;
    17.0 168.0 1178.0 3087.0 6524.0 5880.0 5562.0 7144.0;
    11.0 99.0 919.0 2596.0 5360.0 5762.0 4480.0 7256.0;
    7.0 65.0 647.0 1873.0 4556.0 5058.0 4944.0 7538.0;
    4.0 44.0 509.0 1571.0 4009.0 4527.0 4233.0 6649.0;
    2.0 27.0 345.0 1227.0 3677.0 4229.0 3805.0 6378.0;
    1.0 20.0 231.0 934.0 3197.0 3695.0 3159.0 6454.0;
    1.0 12.0 198.0 707.0 2562.0 3163.0 3232.0 5566.0;
], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21], [1, 2, 3, 4, 5, 6, 7, 8])
# Param ignorado no bloco data: rho

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
@variable(model, g[1:(ne-1)])
@variable(model, m[1:(ne)])
@variable(model, v[1:(nh), 1:(ne)])
@variable(model, w[1:(nh), 1:(nc), 1:(ne)])
@variable(model, uc[i in 1:(nh), j in 1:(nc), s in 1:(ne)])
@variable(model, Duc[i in 1:(nh), j in 1:(nc), s in 1:(ne)])

# Valores iniciais
for i in 1:(itau[1]), s in 1:(ne)
    set_start_value(v[i,s], z[1,s])
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
# g_bounds
for s in 1:(ne-1)
    @NLconstraint(model, g[s] >= 0)
end

# m_bounds
for s in 1:(ne)
    @NLconstraint(model, m[s] >= 0)
end

# continuity
for i in 1:(nh-1), s in 1:(ne)
    @NLconstraint(model, v[i,s] + h*sum((w[i,j,s]/fact[j]) for j in 1:(nc)) == v[i+1,s])
end

# collocation_eqn1
for i in 1:(nh), j in 1:(nc)
    @NLconstraint(model, Duc[i,j,1] == -(m[1]+g[1])*uc[i,j,1])
end

# collocation_eqns
for i in 1:(nh), j in 1:(nc), s in 2:(ne-1)
    @NLconstraint(model, Duc[i,j,s] == g[s-1]*uc[i,j,s-1] - (m[s]+g[s])*uc[i,j,s])
end

# collocation_ne
for i in 1:(nh), j in 1:(nc)
    @NLconstraint(model, Duc[i,j,ne] == g[ne-1]*uc[i,j,ne-1] - m[ne]*uc[i,j,ne])
end


# Para resolver:
# using Ipopt
# set_optimizer(model, Ipopt.Optimizer)
# optimize!(model)
# println("Status: ", termination_status(model))
# println("Objetivo: ", objective_value(model))

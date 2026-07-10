using JuMP

# Arquivo gerado automaticamente a partir de Texto colado(43).txt
# Modelo: prolog

model = Model()

@variable(model, objvar)
@variable(model, x[2:0])

# Valores iniciais vindos de .l do GAMS
set_start_value(objvar, 0.0)

@NLobjective(model, Min, objvar)

# Restrições

# O script de execução deve fazer: set_optimizer(model, Ipopt.Optimizer); optimize!(model)

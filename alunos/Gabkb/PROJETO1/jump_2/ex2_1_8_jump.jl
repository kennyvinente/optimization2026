# Arquivo convertido de GAMS Convert para JuMP
using JuMP


model = Model()

@variable(model, 0 <= x[1:24] <= 100)
@variable(model, objvar)

starts = Dict(1=>6.0, 2=>2.0, 6=>3.0, 8=>21.0, 9=>20.0, 13=>24.0, 17=>3.0, 19=>13.0, 22=>12.0)
for (i,v) in starts
    set_start_value(x[i], v)
end

@objective(model, Min, objvar)

lin = [300.0,270.0,460.0,800.0,740.0,600.0,540.0,380.0,300.0,490.0,380.0,760.0,430.0,250.0,390.0,600.0,210.0,830.0,470.0,680.0,360.0,290.0,400.0,310.0]
quad = [7.0,4.0,6.0,8.0,12.0,9.0,14.0,7.0,13.0,12.0,8.0,4.0,7.0,9.0,16.0,8.0,4.0,10.0,21.0,13.0,17.0,9.0,8.0,4.0]
@constraint(model, e1, -(sum(lin[i]*x[i] - quad[i]*x[i]^2 for i in 1:24)) + objvar == 0.0)

@constraint(model, e2, x[1]+x[2]+x[3]+x[4] == 8.0)
@constraint(model, e3, x[5]+x[6]+x[7]+x[8] == 24.0)
@constraint(model, e4, x[9]+x[10]+x[11]+x[12] == 20.0)
@constraint(model, e5, x[13]+x[14]+x[15]+x[16] == 24.0)
@constraint(model, e6, x[17]+x[18]+x[19]+x[20] == 16.0)
@constraint(model, e7, x[21]+x[22]+x[23]+x[24] == 12.0)
@constraint(model, e8, x[1]+x[5]+x[9]+x[13]+x[17]+x[21] == 29.0)
@constraint(model, e9, x[2]+x[6]+x[10]+x[14]+x[18]+x[22] == 41.0)
@constraint(model, e10, x[3]+x[7]+x[11]+x[15]+x[19]+x[23] == 13.0)
@constraint(model, e11, x[4]+x[8]+x[12]+x[16]+x[20]+x[24] == 21.0)

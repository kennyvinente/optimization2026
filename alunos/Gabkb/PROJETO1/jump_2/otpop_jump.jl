using JuMP

model = Model()

@variable(model, objvar)
@variable(model, x[1:103])

# Positivity from GAMS
for i in 2:17
    set_lower_bound(x[i], 0.0)
end

# Bounds and fixed values from GAMS
fix(x[1], 29.4; force=true)
upper_values = Dict(
    2=>35.25, 3=>38.25, 4=>41.25, 5=>44.25, 6=>47.25, 7=>50.25, 8=>51.15, 9=>52.05,
    10=>52.95, 11=>53.85, 12=>54.75, 13=>55.65, 14=>56.55, 15=>57.45, 16=>58.35, 17=>59.25
)
for (i, ub) in upper_values
    set_upper_bound(x[i], ub)
end
for i in 52:58
    fix(x[i], 3.5; force=true)
end
fix(x[59], 4.0; force=true)
fix(x[60], 7.0; force=true)
fix(x[61], 10.0; force=true)
for i in 62:77
    set_lower_bound(x[i], 1.0)
end

# Aliases
for i in 1:103
    @eval $(Symbol("x", i)) = x[$i]
end

# Known output sequence x18..x34
Y = [88.2, 91.728, 95.39712, 99.2130048, 103.181524992, 107.30878599168,
     111.601137431347, 116.065182928601, 120.707790245745, 125.536101855575,
     130.557545929798, 135.77984776699, 141.21104167767, 146.859483344776,
     152.733862678567, 158.84321718571, 165.196945873138]
for t in 1:17
    @constraint(model, x[17+t] == Y[t])
end

# Production relation: x35..x51, x61..x77, x1..x17, x18..x34
for t in 1:17
    @constraint(model, x[34+t] * x[60+t]^0.2 + x[t] - x[17+t] == 0)
end

# Dynamics x35..x51 linked by x84..x99
coef = 0.00429596009984836
for t in 1:16
    @constraint(model, -coef*x[17+t]*(x[83+t] - 3) - x[34+t] + x[35+t] == 0)
end

# Moving-average filter x52..x77 -> x78..x103
for k in 0:25
    expr = 0.5*x[52+k]
    if k >= 1
        expr += 0.3*x[52+k-1]
    end
    if k >= 2
        expr += 0.2*x[52+k-2]
    end
    @constraint(model, -expr + x[78+k] == 0)
end

# Objective fit on x61..x77
@expression(model, fit_error, sum((10*(1.02)^(t-1) - x[60+t])^2 for t in 1:17))
@constraint(model, -fit_error + objvar == 0)

@objective(model, Min, objvar)

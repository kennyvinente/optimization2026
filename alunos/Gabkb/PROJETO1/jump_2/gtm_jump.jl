using JuMP

function build_gtm_model(; optimizer = nothing)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:63] >= 0)
    @variable(model, objvar)

    # Upper bounds from GAMS
    bounds_up = Dict(
        2=>0.067, 3=>0.067, 4=>0.067, 5=>0.067, 6=>0.033,
        9=>0.3, 10=>0.15, 11=>0.1,
        19=>0.34, 20=>0.35,
        22=>1.39, 23=>1.06, 24=>2.0, 25=>2.62, 26=>3.73,
        27=>0.62, 28=>2.3, 29=>1.03, 30=>0.12, 31=>1.45, 32=>1.46,
        33=>0.48, 34=>0.14, 36=>0.1, 38=>0.48, 39=>0.8,
        40=>2.475, 41=>3.7125, 42=>0.297, 43=>0.7128, 44=>9.6525,
        45=>2.5245, 46=>1.7028, 47=>1.4256, 48=>0.5148, 49=>99.0
    )
    for (i, ub) in bounds_up
        set_upper_bound(x[i], ub)
    end

    fix(x[50], 2.2; force = true)
    fix(x[51], 0.2; force = true)
    fix(x[52], 1.47; force = true)
    fix(x[53], 1.38; force = true)
    for i in 54:63
        set_lower_bound(x[i], 0.2)
    end

    @constraint(model, e1,  x[1]+x[2]+x[3]+x[4]+x[5]+x[6]-x[40] <= 0)
    @constraint(model, e2,  x[7]+x[8]+x[9]+x[10]+x[11]+x[12]+x[13]+x[14]+x[15]+x[16]-x[41] <= 0)
    @constraint(model, e3,  x[17]+x[18]-x[42] <= 0)
    @constraint(model, e4,  x[19]+x[20]-x[43] <= 0)
    @constraint(model, e5,  x[21]+x[22]+x[23]+x[24]+x[25]+x[26]-x[44] <= 0)
    @constraint(model, e6,  x[27]+x[28]+x[29]-x[45] <= 0)
    @constraint(model, e7,  x[30]+x[31]+x[32]-x[46] <= 0)
    @constraint(model, e8,  x[33]+x[34]+x[35]+x[36]+x[37]-x[47] <= 0)
    @constraint(model, e9,  x[38]-x[48] <= 0)
    @constraint(model, e10, x[39]-x[49] <= 0)

    @constraint(model, e11, x[1] - x[50] >= 0)
    @constraint(model, e12, x[17] - x[51] >= 0)
    @constraint(model, e13, x[7] - x[52] >= 0)
    @constraint(model, e14, x[8] - x[53] >= 0)
    @constraint(model, e15, x[9] + x[18] + x[21] - x[54] >= 0)
    @constraint(model, e16, x[2] + x[10] + x[22] - x[55] >= 0)
    @constraint(model, e17, x[3] + x[11] + x[19] + x[23] - x[56] >= 0)
    @constraint(model, e18, x[4] + x[24] - x[57] >= 0)
    @constraint(model, e19, x[5] + x[12] + x[20] + x[25] + x[27] + x[30] + x[33] + x[39] - x[58] >= 0)
    @constraint(model, e20, x[26] + x[28] + x[31] - x[59] >= 0)
    @constraint(model, e21, x[13] + x[29] + x[34] - x[60] >= 0)
    @constraint(model, e22, x[14] + x[35] - x[61] >= 0)
    @constraint(model, e23, x[6] + x[15] + x[32] + x[36] + x[38] - x[62] >= 0)
    @constraint(model, e24, x[16] + x[37] - x[63] >= 0)

    @expression(model, nonlinear_part,
        -4.84/x[50] - 0.14/x[51] - 6.4827/x[52] - 6.6654/x[53] -
        8.89583741831423*x[54]^(-0.666666666666667) -
        20.7788808225955*x[55]^(-0.515151515151515) -
        12.8222379289592*x[56]^(-0.538461538461538) -
        112.274462577384*x[57]^(-0.123595505617978) -
        78.984522912416*x[58]^(-0.538461538461538) -
        325.606233858943*x[59]^(-0.19047619047619) -
        19.9925533406708*x[60]^(-0.492537313432836) -
        20.2959676146409*x[61]^(-0.851851851851852) -
        34.6492709112034*x[62]^(-1.32558139534884) -
        2.07326743881507*x[63]^(-0.754385964912281) -
        (0.0372*x[44] - 6.47537234042553*log(1 - 0.102564102564103*x[44]) -
         0.49*log(1 - 1.38888888888889*x[43]) -
         1.68*log(1 - 0.392156862745098*x[45]) -
         1.2271875*log(1 - 0.581395348837209*x[46]) -
         0.2187*x[46] -
         0.98*log(1 - 0.694444444444444*x[47]) -
         0.35*log(1 - 1.92307692307692*x[48]))
    )

    @expression(model, linear_cost,
        0.25*x[1] + 2.29*x[2] + 2.22*x[3] + 2.03*x[4] + 1.96*x[5] + 2.13*x[6] +
        0.4*x[7] + 0.9*x[8] + 1.15*x[9] + 1.1*x[10] + 1.1*x[11] + 0.8*x[12] +
        0.8*x[13] + 0.65*x[14] + 0.7*x[15] + 0.65*x[16] + 1.5*x[18] +
        0.72*x[19] + 0.46*x[20] + 2.12*x[21] + 1.08*x[22] + 1.01*x[23] +
        0.82*x[24] + 0.75*x[25] + 0.04*x[26] + 0.86*x[27] + 0.14*x[28] +
        0.64*x[29] + 0.77*x[30] + 0.05*x[31] + 0.94*x[32] + 0.53*x[33] +
        0.31*x[34] + 0.58*x[35] + 0.7*x[36] + 1.91*x[37] + 0.43*x[38] +
        6.0*x[39] + 2.0*x[49]
    )

    @constraint(model, e25, -nonlinear_part + linear_cost - objvar == 0)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_gtm_model()
for i in 1:63
    @eval $(Symbol(:x, i)) = x[$i]
end

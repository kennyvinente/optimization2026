using JuMP

function build_immum_model(; optimizer=nothing, set_starts::Bool=true)
    model = optimizer === nothing ? Model() : Model(optimizer)

    @variable(model, x[1:21])
    @variable(model, objvar)

    # x1 is declared Negative in GAMS, then given an explicit upper bound.
    set_upper_bound(x[1], 187217.324724184)
    for i in 2:21
        set_lower_bound(x[i], 0.0)
    end

    if set_starts
        set_start_value(x[1], 187217.324724184)
        set_start_value(x[2], 956.904106888036)
        set_start_value(x[4], 45.5987315339227)
        set_start_value(x[9], 40.6641597628654)
        set_start_value(x[11], 66834.2651808549)
        set_start_value(x[12], 33347.8176607291)
        set_start_value(x[14], 18186.5732712855)
        set_start_value(x[15], 27099.21721716)
        set_start_value(x[17], 938765.155199853)
        set_start_value(x[18], 42000.0)
        set_start_value(x[19], 40000.0)
        set_start_value(x[20], 40000.0)
    end

    @constraint(model, -(x[16]^2 + (50000 - x[17])^2 + (42000 - x[18])^2 +
                         (40000 - x[19])^2 + (40000 - x[20])^2 +
                         (45000 - x[21])^2) + objvar == 0)

    @constraint(model, -x[10] - x[16] == 0)
    @constraint(model, 1044.80727456326*x[2] + 1079.40354193291*x[3] +
                       74.5442033113223*x[4] + 36.3324688408125*x[5] +
                       41.3438438533384*x[6] + 43.2231094830356*x[7] +
                       43.8495313596014*x[8] + 59.5100782737447*x[9] +
                       1.00940093153723*x[10] - x[11] - x[17] == 0)
    @constraint(model, 75.57763951196*x[4] + 36.8361604344007*x[5] +
                       41.9170101494904*x[6] + 43.8223287926491*x[7] +
                       44.4574350070353*x[8] + 60.3350903666908*x[9] +
                       1.0391091639109*x[11] - x[12] - x[18] == 0)
    @constraint(model, 75.456505608033*x[4] + 36.7771203803858*x[5] +
                       41.8498266397494*x[6] + 43.7520914870108*x[7] +
                       44.3861797694312*x[8] + 60.2383868299423*x[9] +
                       1.02284761238063*x[12] - x[13] - x[19] == 0)
    @constraint(model, 1167.30216560492*x[4] + 74.4548991299823*x[5] +
                       84.7245403892903*x[6] + 88.5756558615307*x[7] +
                       89.8593610189442*x[8] + 121.951989954281*x[9] +
                       1.05*x[13] - x[14] - x[20] == 0)
    @constraint(model, 1115.8195763046*x[5] + 1126.3428356729*x[6] +
                       134.503508270593*x[7] + 136.452834477414*x[8] +
                       185.185989647919*x[9] + 1.07600174350434*x[14] -
                       x[15] - x[21] == 0)
    @constraint(model, x[1] - 40.9351218608642*x[2] - 43.2018652628815*x[3] -
                       45.3473311101868*x[4] - 39.805625287987*x[5] -
                       41.3125769494053*x[6] - 41.8781498541141*x[7] -
                       42.1403213448084*x[8] - 46.6038914670337*x[9] == 0)

    @objective(model, Min, objvar)
    return model, x, objvar
end

model, x, objvar = build_immum_model()
for i in 1:21
    @eval $(Symbol(:x, i)) = x[$i]
end

using JuMP
using Ipopt
using CSV
using DataFrames

# ==============================================================================
# 1. MODELO 1: Parabolic Control (Mittelmann / Troeltzsch)
# ==============================================================================
function carregar_mod1(optimizer)
    model = Model(optimizer)
    n = 100; m = 61
    n1 = n - 1; m1 = m - 1
    dt = 1/m; dx = 4*atan(1)/n; h2 = dx^2; nu = 0.004

    facx(j) = (0 < j < n) ? 1.0 : 0.5
    fact(i) = (0 < i < m) ? 1.0 : 0.5
    alpha(i) = (i < m/4) ? -10.5 : 1.0
    yd(i, j) = (i < m/2) ? (1 - cos(j*dx)*(2 - i*dt))/alpha(i) : (1 - cos(j*dx)*(2 - alpha(i)*(i*dt - 0.5)^2 - i*dt))/alpha(i)
    ub(i) = max(2*(i*dt - 0.5), 0.0)
    eq(i, j) = (i >= m/2) ? ((i*dt)^2 + i*dt - 0.75)*cos(j*dx) : 0.0
    es(i) = (i >= m/2) ? (i*dt - 0.5)^4 - ub(i) : 0.0
    ay(i) = (i > m/2) ? 2*(i*dt - 0.5)^2*(1 - i*dt) : 0.0
    au(i) = nu + 1 - (1 + 2*nu)*i*dt

    @variable(model, y[0:m, 0:n])
    @variable(model, 0 <= u[0:m] <= 1)

    @objective(model, Min, 
        0.5 * dx * dt * sum(facx(j) * fact(i) * alpha(i) * (y[i,j] - yd(i,j))^2 for i in 0:m, j in 0:n) +
        0.5 * nu * dt * sum(fact(i) * u[i]^2 for i in 0:m) +
        dt * sum(fact(i) * ay(i) * y[i,n] for i in 1:m) +
        dt * sum(fact(i) * au(i) * u[i] for i in 0:m)
    )

    @constraint(model, [i=0:m1, j=1:n1], (y[i+1,j] - y[i,j])/dt - 0.5*(y[i,j-1] - 2*y[i,j] + y[i,j+1] + y[i+1,j-1] - 2*y[i+1,j] + y[i+1,j+1])/h2 == 0.5*(eq(i,j) + eq(i+1,j)))
    @constraint(model, [j=0:n], y[0,j] == 0)
    @constraint(model, [i=1:m], (y[i,2] - 4*y[i,1] + 3*y[i,0])/(2*dx) == 0)
    @constraint(model, [i=1:m], (y[i,n-2] - 4*y[i,n1] + 3*y[i,n])/(2*dx) + y[i,n]^2 == u[i] + es(i))
    @constraint(model, dx * dt * sum(facx(j) * fact(i) * y[i,j] for i in 0:m, j in 0:n) <= 0)

    return model
end

# ==============================================================================
# 2. MODELO 2: Nonlinear Control 5.1 (Arada / Raymond / Troeltzsch)
# ==============================================================================
function carregar_mod2(optimizer)
    model = Model(optimizer)
    n = 100; m = 100
    n1 = n - 1; m1 = m - 1
    T = 1.0; dt = T/m; l = atan(1); dx = l/n; h2 = dx^2
    s2 = sqrt(2)/2; e1 = exp(1) + 1/exp(1); e13 = exp(1/3); e132 = e13*(e13-1); nu = s2*e132
    
    yt(j) = e1*cos(j*dx)
    limite(i) = min(1.0, max(0.0, (exp(i*dt)-e13)/e132))

    @variable(model, -10 <= y[0:m, 0:n] <= 10)
    @variable(model, 0 <= u[1:m] <= 1)

    @objective(model, Min, 
        0.25 * dx * ((y[m,0] - yt(0))^2 + 2 * sum((y[m,j] - yt(j))^2 for j in 1:n1) + (y[m,n] - yt(n))^2) + 
        0.25 * nu * dt * (2 * sum(u[i]^2 for i in 1:m1) + u[m]^2) + 
        dt * (sum(-exp(-2*i*dt)*y[i,n] + s2*e13*u[i] for i in 1:m1) + 0.5*(-exp(-2*T)*y[m,n] + s2*e13*u[m]))
    )

    @constraint(model, [i=0:m1, j=1:n1], (y[i+1,j] - y[i,j])/dt == 0.5*(y[i,j-1] - 2*y[i,j] + y[i,j+1] + y[i+1,j-1] - 2*y[i+1,j] + y[i+1,j+1])/h2)
    @constraint(model, [j=0:n], y[0,j] == cos(j*dx))
    @constraint(model, [i=1:m], (y[i,2] - 4*y[i,1] + 3*y[i,0])/(2*dx) == 0)
    # Truque do (y^2)^1.5 para lidar com abs(y)^3 sem perder a diferenciabilidade
    @constraint(model, [i=1:m], (y[i,n-2] - 4*y[i,n1] + 3*y[i,n])/(2*dx) + y[i,n] == u[i] + 0.25*exp(-4*i*dt) - limite(i) - y[i,n]*(y[i,n]^2)^1.5)

    return model
end

# ==============================================================================
# 3. MODELO 3: Parabolic Control 5.2-II (Goldberg / Troeltzsch)
# ==============================================================================
function carregar_mod3(optimizer)
    model = Model(optimizer)
    n = 100; m = 100
    n1 = n - 1; m1 = m - 1
    dx = 1/n; T = 1.58; dt = T/m; h2 = dx^2; a = 0.001
    
    yt(j) = 0.5*(1 - (j*dx)^2)

    @variable(model, 0 <= y[0:m, 0:n] <= 1)
    @variable(model, -1 <= u[1:m] <= 1)

    @objective(model, Min, 
        0.25 * dx * ((y[m,0] - yt(0))^2 + 2 * sum((y[m,j] - yt(j))^2 for j in 1:n1) + (y[m,n] - yt(n))^2) + 
        0.25 * a * dt * (2 * sum(u[i]^2 for i in 1:m1) + u[m]^2)
    )

    @constraint(model, [i=0:m1, j=1:n1], (y[i+1,j] - y[i,j])/dt == 0.5*(y[i,j-1] - 2*y[i,j] + y[i,j+1] + y[i+1,j-1] - 2*y[i+1,j] + y[i+1,j+1])/h2)
    @constraint(model, [j=0:n], y[0,j] == 0)
    @constraint(model, [i=1:m], y[i,2] - 4*y[i,1] + 3*y[i,0] == 0)
    @constraint(model, [i=1:m], (y[i,n-2] - 4*y[i,n1] + 3*y[i,n])/(2*dx) == u[i] - y[i,n]^2)

    return model
end

# ==============================================================================
# 4. MODELO 4: Unconstrained Cosine-Sine Boundary
# ==============================================================================
function carregar_mod4(optimizer)
    model = Model(optimizer)
    n = 2500 # Escalado
    
    @variable(model, x[i=0:n+1], start = (1 <= i <= n ? 1.0 : 0.0))
    
    @objective(model, Min, sum(i * (1 - cos(x[i]) + sin(x[i-1]) - sin(x[i+1])) for i in 1:n))
    
    @constraint(model, 4*(x[1]-x[2]^2) + x[2] - x[3]^2 == 0)
    @constraint(model, 8*x[2]*(x[2]^2-x[1]) - 2*(1-x[2]) + 4*(x[2]-x[3]^2) + x[3] - x[4]^2 == 0)
    @constraint(model, 8*x[n-1]*(x[n-1]^2-x[n-2]) - 2*(1-x[n]) + 4*(x[n-1]-x[n]^2) + x[n-2]^2 - x[n-3] == 0)
    @constraint(model, 8*x[n]*(x[n]^2-x[n-1]) - 2*(1-x[n]) + x[n-1]^2 - x[n-2] == 0)
    @constraint(model, x[0] == 0)
    @constraint(model, x[n+1] == 0)

    return model
end

# ==============================================================================
# 5. MODELO 5: Mittelmann Example 5.2 Inequality
# ==============================================================================
function carregar_mod5(optimizer)
    model = Model(optimizer)
    n = 2500 # Escalado
    
    @variable(model, x[i=1:n+2], start = (i % 2 == 1 ? -2.0 : 1.0))
    
    @objective(model, Min, sum(
        100*(x[2*i-1]^2 - x[2*i])^2 + (x[2*i-1] - 1)^2 + 
        90*(x[2*i+1]^2 - x[2*i+2])^2 + (x[2*i+1] - 1)^2 + 
        10*(x[2*i] + x[2*i+2] - 2)^2 + (x[2*i] - x[2*i+2])^2 / 10 
        for i in 1:div(n,2)
    ))
    
    @constraint(model, [i=1:n-7], (2+5*x[i+5]^2)*x[i+5] + 1 + sum(x[j]*(1+x[j]) for j in max(1, i-5):min(n, i+1)) <= 0)
    @constraint(model, x[n+1] == 0)
    @constraint(model, x[n+2] == 0)

    return model
end

# ==============================================================================
# MOTOR DE EXECUÇÃO EM LOTE
# ==============================================================================
function rodar_benchmark_elite()
    instancias = [
        ("Mittelmann_Parabolic_Ctrl", carregar_mod1),
        ("Nonlinear_Ctrl_5.1", carregar_mod2),
        ("Goldberg_Parabolic_5.2", carregar_mod3),
        ("Cos_Sin_Boundary", carregar_mod4),
        ("Mittelmann_Ineq_5.2", carregar_mod5)
    ]
    
    resultados = DataFrame(Instancia=String[], Status=String[], Objetivo=Float64[], Tempo_s=Float64[])
    optimizer = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0, "max_iter" => 3000)

    println("Iniciando Benchmark do Esquadrão de Elite...\n")

    for (nome, func) in instancias
        print("Modelando e Resolvendo [$nome]... ")
        model = func(optimizer)
        
        tempo = @elapsed optimize!(model)
        status = termination_status(model)
        
        if status == MOI.LOCALLY_SOLVED || status == MOI.OPTIMAL
            obj = objective_value(model)
        else
            obj = NaN
        end
        
        push!(resultados, (nome, string(status), obj, tempo))
        println("Concluído! ($status)")
    end

    CSV.write("resultados_benchmark_elite.csv", resultados)
    println("\n✔ Relatório finalizado! Verifique o arquivo 'resultados_benchmark_elite.csv'.")
end

rodar_benchmark_elite()
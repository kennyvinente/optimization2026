using JuMP
using Ipopt
using CSV
using DataFrames

# 1. Função global para o Julia entender o "power" do GAMS
power(a, b) = a^b

function interpretar_e_resolver(caminho_arquivo)
    println("\n========================================")
    println("Lendo e Interpretando: ", basename(caminho_arquivo))
    
    texto = read(caminho_arquivo, String)

    # 2. Corta o cabeçalho inútil e pega só a matemática
    idx = findfirst("objcon..", texto)
    if idx === nothing
        println("  ➜ FALHA: Equação objetivo (objcon) não encontrada.")
        return "FALHA_LEITURA", NaN
    end
    texto_util = texto[idx.start : end]

    # 3. Limpeza Extrema
    texto_util = replace(texto_util, "\r" => "")
    texto_util = replace(texto_util, "\n" => "")

    # 4. Tradução Automática: GAMS -> Julia
    texto_util = replace(texto_util, r"x\('(\d+)'\)" => s"x[\1]")
    texto_util = replace(texto_util, "=e=" => "==")
    texto_util = replace(texto_util, "=l=" => "<=")
    texto_util = replace(texto_util, "=g=" => ">=")

    # 5. Descobre automaticamente quantas variáveis o problema tem
    max_var = 0
    for m in eachmatch(r"x\[(\d+)\]", texto_util)
        max_var = max(max_var, parse(Int, m.captures[1]))
    end

    # 6. Escreve o código fonte Julia dinamicamente na memória
    func_name = "resolver_instancia"
    codigo_jl = "function $func_name()\n"
    codigo_jl *= "    model = Model(Ipopt.Optimizer)\n"
    codigo_jl *= "    set_silent(model)\n"
    codigo_jl *= "    @variable(model, x[1:$max_var])\n"

    # 7. Separa as equações e monta o modelo
    for inst in split(texto_util, ";")
        inst = strip(inst)
        if isempty(inst) continue end

        if occursin("x.lo", inst)
            m = match(r"x\.lo\[(\d+)\]\s*=\s*(.+)", inst)
            if m !== nothing codigo_jl *= "    set_lower_bound(x[$(m[1])], $(m[2]))\n" end
        elseif occursin("x.up", inst)
            m = match(r"x\.up\[(\d+)\]\s*=\s*(.+)", inst)
            if m !== nothing codigo_jl *= "    set_upper_bound(x[$(m[1])], $(m[2]))\n" end
        elseif occursin("x.fx", inst)
            m = match(r"x\.fx\[(\d+)\]\s*=\s*(.+)", inst)
            if m !== nothing codigo_jl *= "    fix(x[$(m[1])], $(m[2]); force=true)\n" end
        
        elseif occursin("..", inst)
            partes = split(inst, "..")
            nome_eq = strip(partes[1])
            expr = strip(partes[2])

            if nome_eq == "objcon"
                expr = replace(expr, r"obj\s*==\s*" => "")
                codigo_jl *= "    @objective(model, Min, $expr)\n"
            else
                codigo_jl *= "    @constraint(model, $expr)\n"
            end
        end
    end

    codigo_jl *= "    optimize!(model)\n"
    codigo_jl *= "    return termination_status(model), objective_value(model)\n"
    codigo_jl *= "end\n"

    # 8. MOMENTO CRÍTICO: Compila e Roda
    print("  ➜ Compilando e resolvendo... ")
    try
        eval(Meta.parse(codigo_jl)) 
        status, obj = eval(Meta.parse("$func_name()")) 
        println("Pronto!")
        return string(status), obj
    catch e
        println("ERRO DE COMPILADOR! A equação é pesada demais ou tem sintaxe não suportada.")
        return "FALHA_COMPILACAO", NaN
    end
end

# ==============================================================================
# MOTOR DO BENCHMARK
# ==============================================================================
function iniciar_automacao()
    # Veja o uso do '=' e do 'raw' antes das aspas!
    PASTA_MODELOS = raw"D:\Codigos\otimização\optimization2026\trabalho 1\models"
    
    if !isdir(PASTA_MODELOS)
        println("Erro: A pasta '$PASTA_MODELOS' não foi encontrada.")
        return
    end

    arquivos = filter(x -> endswith(x, ".txt"), readdir(PASTA_MODELOS))
    resultados = DataFrame(Instancia=String[], Status=String[], Objetivo=Float64[])

    println("Iniciando Transpilador para $(length(arquivos)) arquivos...\n")

    for arquivo in arquivos
        caminho = joinpath(PASTA_MODELOS, arquivo)
        status, obj = interpretar_e_resolver(caminho)
        
        push!(resultados, (arquivo, status, obj))
        println("  ➜ Status final: $status | Objetivo: $(round(obj, digits=4))")
    end

    CSV.write("resultados_interpretador_gams.csv", resultados)
    println("\n✔ Processo 100% Finalizado! CSV salvo.")
end

iniciar_automacao()
using Pkg
Pkg.activate(".")

println("Adicionando pacotes de Otimização...")
Pkg.add(["JuMP", "Ipopt", "MadNLP", "NLopt", "Optim", "DataFrames", "CSV", "HTTP", "Gumbo", "Cascadia"])

println("Ambiente configurado com sucesso!")

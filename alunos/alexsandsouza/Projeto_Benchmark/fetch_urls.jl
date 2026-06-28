using HTTP
using Gumbo
using Cascadia

url = "https://plato.asu.edu/ftp/ampl-nlp-source/"
response = HTTP.get(url)
html = parsehtml(String(response.body))
links = eachmatch(Selector("a"), html.root)

mod_files = [nodeText(l) for l in links if endswith(nodeText(l), ".mod")]
println("Encontrados ", length(mod_files), " arquivos .mod:")
for m in mod_files
    println(m)
end

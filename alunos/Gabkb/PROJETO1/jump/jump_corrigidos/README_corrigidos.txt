Arquivos JuMP corrigidos

Alterações principais:
1) ex1_160_jump.jl e ex1_320_jump.jl
   - Corrigido o acesso inválido a vizinhos da malha nas bordas.
   - A restrição PDE foi reescrita com loops for + if, evitando índices negativos como x[-158] e x[-318].
   - Adicionado set_string_names_on_creation(model, false) após model = Model().

2) ex4_2_160_jump.jl e ex4_2_320_jump.jl
   - Não havia erro estrutural de índice: u é definido em 0:n1 e a PDE usa i,j em 1:n.
   - Mantida a estrutura original.
   - Adicionado set_string_names_on_creation(model, false).

3) ex8_2_2_jump.jl e ex8_2_3_jump.jl
   - A função objetivo enorme foi dividida em blocos @NLexpression para evitar StackOverflow na macro/parser do JuMP.
   - Mantidas as restrições originais.
   - Adicionado set_string_names_on_creation(model, false).

Como usar:
- Baixe jump_corrigidos.zip no diretório do projeto.
- Extraia sobrescrevendo a pasta jump:

unzip -o jump_corrigidos.zip -d jump

Depois teste, por exemplo:

julia --project=. rodar_um_ipopt.jl jump/ex1_160_jump.jl
julia --project=. rodar_um_ipopt.jl jump/ex1_320_jump.jl
julia --project=. rodar_um_ipopt.jl jump/ex8_2_2_jump.jl

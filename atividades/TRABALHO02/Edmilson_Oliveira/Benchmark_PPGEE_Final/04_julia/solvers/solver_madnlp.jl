# Benchmark NLP - PPGEE/UFAM

## Benchmark de Solucionadores para Problemas de Programação Não Linear

Autor: **Edmilson da Silva Oliveira**

Programa de Pós-Graduação em Engenharia Elétrica (PPGEE)

Universidade Federal do Amazonas (UFAM)

---

## Objetivo

Este projeto implementa um benchmark para avaliação de solucionadores de Programação Não Linear (NLP), utilizando problemas provenientes das bibliotecas AMPL e COCONUT/GAMS.

O benchmark automatiza a execução dos modelos, coleta métricas de desempenho e gera relatórios para comparação entre diferentes solvers.

---

## Solvers avaliados

- Ipopt
- MadNLP
- Optim
- NLopt
- Uno

---

## Estrutura

```
Benchmark_PPGEE_Final
│
├── 01_download
├── 02_ampl
├── 03_gams
├── 04_julia
├── 05_resultados
│
├── config.jl
├── main.jl
├── Project.toml
└── Manifest.toml
```

---

## Execução

Para executar todo o benchmark:

```bash
julia main.jl
```

---

## Resultados

Os resultados são gravados automaticamente em:

```
05_resultados/csv/
```

Exemplos:

- benchmark_ampl.csv
- comparacao_final.csv

---

## Benchmark GAMS

Quantidade de modelos:

- Total: 159
- Resolvidos: 142
- Falhas: 17
- Taxa de sucesso: 89,31%

---

## Benchmark AMPL

Problemas avaliados:

- Biblioteca AMPL-NLP
- Lista com 47 problemas

---

## Tecnologias

- Julia
- AMPL
- GAMS
- Ipopt
- MadNLP
- CSV.jl
- DataFrames.jl

---

## Observação

Os arquivos `.nl` de grande porte não foram incluídos neste repositório devido ao limite de tamanho imposto pelo GitHub. Eles podem ser obtidos novamente a partir das bibliotecas originais utilizadas no benchmark.

---

## Autor

Edmilson da Silva Oliveira e Renato Guuimarães

PPGEE — Universidade Federal do Amazonas
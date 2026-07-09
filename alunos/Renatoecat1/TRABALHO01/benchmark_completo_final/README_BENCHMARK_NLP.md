# Benchmark NLP Workflow

This folder contains the recovered benchmark artifacts and a consolidated
workflow for AMPL `.nl` instances.

## Project Inventory

- `resultados/`: existing CSV outputs for Ipopt, MadNLP comparison, COCONUT
  references, and summaries.
- `logs/ipopt/`: Ipopt execution logs for the 97 benchmark instances already
  represented in the result CSVs.
- `logs/gams/`: GAMS/COCONUT reference logs.
- `scripts/`: original helper scripts plus `benchmark_nlp_workflow.py`, the
  robust end-to-end workflow.
- `nl_files/`: expected location for the 97 `.nl` files. This folder is not
  present in the recovered ZIP, so the workflow records an empty manifest until
  the `.nl` files are restored or a different `--nl-dir` is supplied.

## Rebuild Tables From Existing Results

Run from `atividades/TRABALHO01/benchmark_completo_final`:

```powershell
python scripts\benchmark_nlp_workflow.py
```

Generated files:

- `resultados/instances_manifest.csv`
- `resultados/benchmark_instances_identificados.csv`
- `resultados/tabela_benchmark_publicacao.csv`
- `resultados/resumo_benchmark_publicacao.csv`

## Solve All `.nl` Files

Place the benchmark instances in `nl_files/` or pass another folder:

```powershell
python scripts\benchmark_nlp_workflow.py `
  --run `
  --nl-dir nl_files `
  --ipopt-cmd "C:\path\to\ipopt.exe" `
  --madnlp-cmd "C:\path\to\madnlp.exe"
```

The solver commands can also be configured with environment variables:

- `IPOPT_CMD`
- `MADNLP_CMD`

The run produces normalized per-solver CSVs and then regenerates the comparison
and publication tables.

## Reported Metrics

For each solver/instance pair, the workflow records:

- objective value
- iterations
- solve status
- execution time
- log path
- error message, when applicable

The publication table compares Ipopt and MadNLP, computes signed and signless
relative gaps, and adds optimality gaps against COCONUT references when problem
names match available reference values.

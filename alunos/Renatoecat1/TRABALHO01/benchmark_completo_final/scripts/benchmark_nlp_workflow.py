"""End-to-end workflow for AMPL .nl NLP benchmark runs.

The workflow has two modes:
1. Rebuild publication tables from existing CSV files.
2. Execute every .nl file with configured solver executables and then rebuild
   the same tables.

It intentionally avoids machine-specific paths. Solver commands can be passed
with --ipopt-cmd and --madnlp-cmd or provided through IPOPT_CMD and MADNLP_CMD.
"""

from __future__ import annotations

import argparse
import csv
import math
import os
import re
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import pandas as pd


SUCCESS_STATUSES = {
    "OPTIMAL",
    "SOLVE_SUCCEEDED",
    "SOLVED_TO_ACCEPTABLE_LEVEL",
    "LOCALLY_SOLVED",
    "FIRST_ORDER",
    "ACCEPTABLE",
}


@dataclass(frozen=True)
class SolverConfig:
    name: str
    command: str | None
    timeout_s: int


def finite_float(value: object) -> float | None:
    if value is None or (isinstance(value, float) and math.isnan(value)):
        return None
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if math.isfinite(number) else None


def rel_gap_pct(candidate: object, reference: object, signless: bool = False) -> float | None:
    cand = finite_float(candidate)
    ref = finite_float(reference)
    if cand is None or ref is None:
        return None
    if signless:
        cand = abs(cand)
        ref = abs(ref)
    return 100.0 * abs(cand - ref) / max(1.0, abs(ref))


def discover_nl_files(nl_dir: Path) -> list[Path]:
    if not nl_dir.exists():
        return []
    return sorted(path for path in nl_dir.rglob("*.nl") if path.is_file())


def write_manifest(nl_files: Iterable[Path], out_csv: Path) -> None:
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    with out_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["problema", "nl_path", "size_bytes"])
        writer.writeheader()
        for nl_file in nl_files:
            writer.writerow(
                {
                    "problema": nl_file.stem,
                    "nl_path": str(nl_file),
                    "size_bytes": nl_file.stat().st_size,
                }
            )


def parse_status(text: str, return_code: int | None) -> str:
    status_patterns = [
        (r"Optimal Solution Found", "OPTIMAL"),
        (r"SOLVE_SUCCEEDED", "SOLVE_SUCCEEDED"),
        (r"SOLVED_TO_ACCEPTABLE_LEVEL", "SOLVED_TO_ACCEPTABLE_LEVEL"),
        (r"Maximum Number of Iterations Exceeded", "MAX_ITER"),
        (r"Restoration Failed", "RESTORATION_FAILED"),
        (r"TIMEOUT", "TIMEOUT"),
    ]
    for pattern, status in status_patterns:
        if re.search(pattern, text, flags=re.IGNORECASE):
            return status

    exit_lines = re.findall(r"EXIT:\s*(.+)", text)
    if exit_lines:
        return exit_lines[-1].strip()

    if return_code is None:
        return "ERROR"
    return "RET_0" if return_code == 0 else f"RET_{return_code}"


def parse_iterations(text: str) -> int | None:
    candidates = []

    for pattern in [
        r"Number of Iterations\.{2,}:\s*(\d+)",
        r"Number of iterations\s*:\s*(\d+)",
        r"iterations?\s*[=:]\s*(\d+)",
    ]:
        candidates.extend(int(match) for match in re.findall(pattern, text, flags=re.IGNORECASE))

    for match in re.findall(r"^\s*(\d+)\s+[-+]?\d", text, flags=re.MULTILINE):
        candidates.append(int(match))

    return max(candidates) if candidates else None


def parse_objective(text: str) -> float | None:
    patterns = [
        r"Objective(?:\s+value)?\s*[=:]\s*([-+]?\d+(?:\.\d*)?(?:[eE][-+]?\d+)?)",
        r"Final objective(?:\s+value)?\s*[=:]\s*([-+]?\d+(?:\.\d*)?(?:[eE][-+]?\d+)?)",
        r"objective value\s+([-+]?\d+(?:\.\d*)?(?:[eE][-+]?\d+)?)",
    ]
    for pattern in patterns:
        values = re.findall(pattern, text, flags=re.IGNORECASE)
        if values:
            return float(values[-1])

    iter_values = re.findall(
        r"^\s*\d+\s+([-+]?\d+(?:\.\d*)?[eE][-+]?\d+)",
        text,
        flags=re.MULTILINE,
    )
    if iter_values:
        return float(iter_values[-1])
    return None


def parse_solver_log(log_file: Path, return_code: int | None) -> dict[str, object]:
    text = log_file.read_text(encoding="utf-8", errors="ignore") if log_file.exists() else ""
    return {
        "status": parse_status(text, return_code),
        "objetivo": parse_objective(text),
        "iteracoes": parse_iterations(text),
    }


def run_solver_on_nl(solver: SolverConfig, nl_file: Path, logs_dir: Path) -> dict[str, object]:
    logs_dir.mkdir(parents=True, exist_ok=True)
    log_file = logs_dir / solver.name.lower() / f"{nl_file.stem}.log"
    log_file.parent.mkdir(parents=True, exist_ok=True)

    started = time.perf_counter()
    return_code = None
    error = ""

    if not solver.command:
        return {
            "problema": nl_file.stem,
            "solver": solver.name,
            "status": "MISSING_SOLVER_COMMAND",
            "objetivo": None,
            "iteracoes": None,
            "tempo_s": 0.0,
            "log": str(log_file),
            "erro": f"{solver.name} command was not configured",
        }

    command = [solver.command, str(nl_file)]
    try:
        with log_file.open("w", encoding="utf-8", errors="ignore") as handle:
            proc = subprocess.run(
                command,
                stdout=handle,
                stderr=subprocess.STDOUT,
                timeout=solver.timeout_s,
                check=False,
            )
        return_code = proc.returncode
    except subprocess.TimeoutExpired:
        error = f"Timeout after {solver.timeout_s} seconds"
        log_file.write_text("TIMEOUT\n" + error, encoding="utf-8")
    except Exception as exc:  # pragma: no cover - defensive for local solver failures
        error = str(exc)
        log_file.write_text("ERROR\n" + error, encoding="utf-8")

    elapsed = round(time.perf_counter() - started, 6)
    parsed = parse_solver_log(log_file, return_code)
    parsed.update(
        {
            "problema": nl_file.stem,
            "solver": solver.name,
            "tempo_s": elapsed,
            "log": str(log_file),
            "erro": error,
        }
    )
    return parsed


def normalize_solver_csv(csv_path: Path, solver: str) -> pd.DataFrame:
    if not csv_path.exists():
        return pd.DataFrame()

    df = pd.read_csv(csv_path)
    rename_candidates = {
        "problem": "problema",
        "name": "problema",
        "objective": "objetivo",
        "obj": "objetivo",
        "objval": "objetivo",
        "objective_value": "objetivo",
        "iterations": "iteracoes",
        "iter": "iteracoes",
        "iters": "iteracoes",
        "cpu_s": "tempo_s",
        "time_s": "tempo_s",
        "tempo_segundos": "tempo_s",
        "elapsed_time": "tempo_s",
        "solve_time": "tempo_s",
    }
    df = df.rename(columns={col: rename_candidates.get(col, col) for col in df.columns})

    if "problema" not in df.columns:
        raise ValueError(f"{csv_path} does not contain a problem/name column")
    if "solver" not in df.columns:
        df["solver"] = solver
    for column in ["status", "objetivo", "iteracoes", "tempo_s", "log", "erro"]:
        if column not in df.columns:
            df[column] = None

    return df[["problema", "solver", "status", "objetivo", "iteracoes", "tempo_s", "log", "erro"]]


def load_or_run_results(args: argparse.Namespace, nl_files: list[Path]) -> tuple[pd.DataFrame, pd.DataFrame]:
    results_dir = Path(args.results_dir)

    if args.run:
        rows = []
        solvers = [
            SolverConfig("Ipopt", args.ipopt_cmd or os.getenv("IPOPT_CMD"), args.timeout),
            SolverConfig("MadNLP", args.madnlp_cmd or os.getenv("MADNLP_CMD"), args.timeout),
        ]
        for nl_file in nl_files:
            for solver in solvers:
                rows.append(run_solver_on_nl(solver, nl_file, Path(args.logs_dir)))

        all_results = pd.DataFrame(rows)
        results_dir.mkdir(parents=True, exist_ok=True)
        all_results.to_csv(results_dir / "resultados_todos_solvers.csv", index=False)
        ipopt = all_results[all_results["solver"].str.lower() == "ipopt"].copy()
        madnlp = all_results[all_results["solver"].str.lower() == "madnlp"].copy()
        ipopt.to_csv(results_dir / "resultados_ampl_ipopt.csv", index=False)
        madnlp.to_csv(results_dir / "resultados_ampl_madnlp.csv", index=False)
        return ipopt, madnlp

    ipopt_csv = Path(args.ipopt_csv) if args.ipopt_csv else results_dir / "resultados_ampl_ipopt.csv"
    madnlp_csv = Path(args.madnlp_csv) if args.madnlp_csv else results_dir / "resultados_ampl_madnlp.csv"

    ipopt = normalize_solver_csv(ipopt_csv, "Ipopt")
    madnlp = normalize_solver_csv(madnlp_csv, "MadNLP")

    if ipopt.empty and (results_dir / "resultados_ipopt_final.csv").exists():
        ipopt = normalize_solver_csv(results_dir / "resultados_ipopt_final.csv", "Ipopt")
    if madnlp.empty and (results_dir / "comparacao_ipopt_madnlp_gap_corrigido.csv").exists():
        comparison = pd.read_csv(results_dir / "comparacao_ipopt_madnlp_gap_corrigido.csv")
        madnlp = pd.DataFrame(
            {
                "problema": comparison["problema"],
                "solver": "MadNLP",
                "status": comparison.get("status_madnlp"),
                "objetivo": comparison.get("obj_madnlp"),
                "iteracoes": comparison.get("iter_madnlp"),
                "tempo_s": comparison.get("tempo_madnlp_s"),
                "log": None,
                "erro": comparison.get("erro"),
            }
        )

    return ipopt, madnlp


def load_reference(reference_csv: Path) -> pd.DataFrame:
    if not reference_csv.exists():
        return pd.DataFrame(columns=["problema", "obj_ref", "status_ref", "reference_source"])

    ref = pd.read_csv(reference_csv)
    ref = ref.rename(
        columns={
            "obj": "obj_ref",
            "objective": "obj_ref",
            "status": "status_ref",
            "modelstatus": "status_ref",
            "arquivo": "reference_source",
        }
    )
    for column in ["obj_ref", "status_ref", "reference_source"]:
        if column not in ref.columns:
            ref[column] = None
    return ref[["problema", "obj_ref", "status_ref", "reference_source"]]


def build_comparison(ipopt: pd.DataFrame, madnlp: pd.DataFrame, reference: pd.DataFrame) -> pd.DataFrame:
    ip = ipopt.add_prefix("ipopt_").rename(columns={"ipopt_problema": "problema"})
    md = madnlp.add_prefix("madnlp_").rename(columns={"madnlp_problema": "problema"})

    comparison = pd.merge(ip, md, on="problema", how="outer")
    comparison = pd.merge(comparison, reference, on="problema", how="left")

    comparison["gap_ipopt_madnlp_pct"] = [
        rel_gap_pct(a, b) for a, b in zip(comparison["ipopt_objetivo"], comparison["madnlp_objetivo"])
    ]
    comparison["gap_ipopt_madnlp_abs_sign_pct"] = [
        rel_gap_pct(a, b, signless=True)
        for a, b in zip(comparison["ipopt_objetivo"], comparison["madnlp_objetivo"])
    ]
    comparison["gap_ipopt_ref_pct"] = [
        rel_gap_pct(a, b) for a, b in zip(comparison["ipopt_objetivo"], comparison["obj_ref"])
    ]
    comparison["gap_madnlp_ref_pct"] = [
        rel_gap_pct(a, b) for a, b in zip(comparison["madnlp_objetivo"], comparison["obj_ref"])
    ]
    comparison["ipopt_success"] = comparison["ipopt_status"].isin(SUCCESS_STATUSES)
    comparison["madnlp_success"] = comparison["madnlp_status"].isin(SUCCESS_STATUSES)

    ordered_columns = [
        "problema",
        "ipopt_status",
        "ipopt_objetivo",
        "ipopt_iteracoes",
        "ipopt_tempo_s",
        "madnlp_status",
        "madnlp_objetivo",
        "madnlp_iteracoes",
        "madnlp_tempo_s",
        "gap_ipopt_madnlp_pct",
        "gap_ipopt_madnlp_abs_sign_pct",
        "obj_ref",
        "status_ref",
        "gap_ipopt_ref_pct",
        "gap_madnlp_ref_pct",
        "reference_source",
        "ipopt_success",
        "madnlp_success",
    ]
    for column in ordered_columns:
        if column not in comparison.columns:
            comparison[column] = None
    return comparison[ordered_columns].sort_values("problema")


def solver_summary(comparison: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for solver in ["ipopt", "madnlp"]:
        status = comparison[f"{solver}_status"]
        objective = comparison[f"{solver}_objetivo"]
        time_s = pd.to_numeric(comparison[f"{solver}_tempo_s"], errors="coerce")
        iterations = pd.to_numeric(comparison[f"{solver}_iteracoes"], errors="coerce")
        success = comparison[f"{solver}_success"]
        rows.append(
            {
                "solver": "Ipopt" if solver == "ipopt" else "MadNLP",
                "instances": int(status.notna().sum()),
                "successes": int(success.sum()),
                "success_rate_pct": round(100.0 * success.sum() / max(1, status.notna().sum()), 2),
                "median_time_s": round(float(time_s.median()), 6) if time_s.notna().any() else None,
                "mean_time_s": round(float(time_s.mean()), 6) if time_s.notna().any() else None,
                "median_iterations": round(float(iterations.median()), 2)
                if iterations.notna().any()
                else None,
                "mean_iterations": round(float(iterations.mean()), 2) if iterations.notna().any() else None,
                "objective_values": int(objective.notna().sum()),
            }
        )
    return pd.DataFrame(rows)


def write_identified_instances(nl_files: list[Path], comparison: pd.DataFrame, out_csv: Path) -> None:
    from_nl = {path.stem: str(path) for path in nl_files}
    problems = sorted(set(from_nl) | set(comparison["problema"].dropna().astype(str)))
    rows = [
        {
            "problema": problem,
            "nl_path": from_nl.get(problem),
            "source": "nl_files" if problem in from_nl else "existing_results",
        }
        for problem in problems
    ]
    pd.DataFrame(rows).to_csv(out_csv, index=False)


def main() -> None:
    parser = argparse.ArgumentParser(description="Run and compare NLP benchmark .nl files.")
    parser.add_argument("--nl-dir", default="nl_files", help="Folder containing AMPL .nl files.")
    parser.add_argument("--results-dir", default="resultados", help="Folder for CSV outputs.")
    parser.add_argument("--logs-dir", default="logs", help="Folder for solver logs.")
    parser.add_argument("--reference-csv", default="resultados/coconut_validos_status_2_13.csv")
    parser.add_argument("--ipopt-csv", default=None, help="Existing Ipopt CSV to normalize.")
    parser.add_argument("--madnlp-csv", default=None, help="Existing MadNLP CSV to normalize.")
    parser.add_argument("--ipopt-cmd", default=None, help="Path to Ipopt executable.")
    parser.add_argument("--madnlp-cmd", default=None, help="Path to MadNLP executable.")
    parser.add_argument("--timeout", type=int, default=7200, help="Per-instance timeout in seconds.")
    parser.add_argument("--run", action="store_true", help="Run solvers instead of only rebuilding tables.")
    args = parser.parse_args()

    nl_files = discover_nl_files(Path(args.nl_dir))
    results_dir = Path(args.results_dir)
    write_manifest(nl_files, results_dir / "instances_manifest.csv")

    if args.run and not nl_files:
        raise SystemExit(f"No .nl files found under {args.nl_dir}")

    ipopt, madnlp = load_or_run_results(args, nl_files)
    if ipopt.empty and madnlp.empty:
        raise SystemExit("No solver results found. Provide CSV files or run with --run.")

    reference = load_reference(Path(args.reference_csv))
    comparison = build_comparison(ipopt, madnlp, reference)
    summary = solver_summary(comparison)

    results_dir.mkdir(parents=True, exist_ok=True)
    write_identified_instances(nl_files, comparison, results_dir / "benchmark_instances_identificados.csv")
    comparison.to_csv(results_dir / "tabela_benchmark_publicacao.csv", index=False)
    summary.to_csv(results_dir / "resumo_benchmark_publicacao.csv", index=False)

    print(f"NL instances discovered: {len(nl_files)}")
    print(f"Benchmark instances identified: {comparison['problema'].nunique()}")
    print(f"Instance inventory: {results_dir / 'benchmark_instances_identificados.csv'}")
    print(f"Publication table: {results_dir / 'tabela_benchmark_publicacao.csv'}")
    print(f"Summary table: {results_dir / 'resumo_benchmark_publicacao.csv'}")
    print(summary.to_string(index=False))


if __name__ == "__main__":
    main()

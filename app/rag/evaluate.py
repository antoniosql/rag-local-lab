from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

from settings import Settings
from rag.pipeline import RAGPipeline


ABSTENTION_TEXT = "No tengo evidencia suficiente en los documentos proporcionados."


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Mini evaluación manual asistida del pipeline RAG")
    parser.add_argument(
        "--csv",
        type=str,
        default="../evaluation/questions.csv",
        help="Ruta al CSV de evaluación",
    )
    parser.add_argument("--top-k", type=int, default=None, help="Override de top_k")
    return parser


def main() -> None:
    args = build_parser().parse_args()

    settings = Settings.from_env()
    pipeline = RAGPipeline(settings)

    csv_path = Path(args.csv)
    if not csv_path.exists():
        raise FileNotFoundError(f"No existe el CSV de evaluación: {csv_path}")

    rows: list[dict] = []
    with csv_path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows.extend(reader)

    results: list[dict] = []
    for row in rows:
        response = pipeline.ask(question=row["question"], top_k=args.top_k)
        answer = response["answer"]
        sources = response.get("sources", [])

        should_abstain = row["should_abstain"].strip().lower() == "true"
        expected_source = (row.get("expected_source") or "").strip()

        abstained = ABSTENTION_TEXT in answer
        source_ok = expected_source in sources if expected_source else True
        abstention_ok = abstained == should_abstain

        results.append(
            {
                "id": row["id"],
                "question": row["question"],
                "expected_source": expected_source,
                "should_abstain": should_abstain,
                "sources_returned": sources,
                "abstained": abstained,
                "source_ok": source_ok,
                "abstention_ok": abstention_ok,
                "pass": source_ok and abstention_ok,
            }
        )

    passed = sum(1 for item in results if item["pass"])
    total = len(results)

    output = {
        "summary": {
            "passed": passed,
            "total": total,
            "pass_rate": round(passed / total, 3) if total else 0.0,
        },
        "results": results,
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

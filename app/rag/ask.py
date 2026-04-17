from __future__ import annotations

import argparse
import json

from settings import Settings
from rag.pipeline import RAGPipeline


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Consulta el pipeline RAG local")
    parser.add_argument("--question", type=str, required=True, help="Pregunta del usuario")
    parser.add_argument("--top-k", type=int, default=None, help="Número de fragmentos a recuperar")
    parser.add_argument(
        "--only-retrieve",
        action="store_true",
        help="Muestra solo los fragmentos recuperados, sin generación final",
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    settings = Settings.from_env()
    pipeline = RAGPipeline(settings)

    if args.only_retrieve:
        hits = pipeline.retrieve(question=args.question, top_k=args.top_k)
        print(json.dumps({"question": args.question, "hits": hits}, ensure_ascii=False, indent=2))
        return

    result = pipeline.ask(question=args.question, top_k=args.top_k)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

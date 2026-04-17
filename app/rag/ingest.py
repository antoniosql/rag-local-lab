from __future__ import annotations

import argparse
import json
from pathlib import Path

from settings import Settings
from rag.pipeline import RAGPipeline


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Ingresa documentos locales en Qdrant usando embeddings de Ollama")
    parser.add_argument(
        "--docs-dir",
        type=str,
        default="../docs",
        help="Directorio con documentos .md o .txt",
    )
    parser.add_argument(
        "--force-recreate",
        action="store_true",
        help="Borra y recrea la colección antes de indexar",
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    settings = Settings.from_env()
    pipeline = RAGPipeline(settings)

    result = pipeline.ingest_directory(
        docs_dir=Path(args.docs_dir),
        force_recreate=args.force_recreate,
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

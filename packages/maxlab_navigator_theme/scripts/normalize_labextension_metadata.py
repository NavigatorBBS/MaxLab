import json
import sys
from pathlib import Path


def normalize_paths(value):
    if isinstance(value, str):
        return value.replace("\\", "/")
    if isinstance(value, list):
        return [normalize_paths(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize_paths(item) for key, item in value.items()}
    return value


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: normalize_labextension_metadata.py <package.json>")

    package_path = Path(sys.argv[1])
    payload = json.loads(package_path.read_text(encoding="utf-8"))

    jupyterlab = payload.get("jupyterlab")
    if isinstance(jupyterlab, dict) and isinstance(jupyterlab.get("_build"), dict):
        jupyterlab["_build"] = normalize_paths(jupyterlab["_build"])

    package_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

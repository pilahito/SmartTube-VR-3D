"""Reject Godot errors even when the process exits successfully."""
import argparse
from pathlib import Path

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("log", type=Path)
    parser.add_argument("--marker", required=True)
    args = parser.parse_args()
    lines = args.log.read_text(encoding="utf-8", errors="replace").splitlines()
    errors = [line for line in lines if line.lstrip().startswith(("SCRIPT ERROR:", "ERROR:"))]
    if not any(line.strip() == args.marker or line.strip().startswith(args.marker + ":") for line in lines):
        raise SystemExit("Missing completion marker: " + args.marker)
    if errors:
        raise SystemExit("\n".join(errors))
    print("Godot log verified: " + args.marker)

if __name__ == "__main__":
    main()

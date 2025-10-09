import pathlib
import sys
import numpy


def main() -> None:
    print(f"Python prefix: {sys.prefix}")
    print(f"Python executable: {sys.executable}")

    if "rules_conda" not in sys.prefix:
        raise SystemExit(f"Expected prefix to be a Conda environment")


if __name__ == "__main__":
    main()

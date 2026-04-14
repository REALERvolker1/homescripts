#!/usr/bin/env python3
"""
csv_to_md.py – Convert CSV (or stdin) → Markdown table

Features
--------
* Handles quoted fields, embedded delimiters, new‑lines, etc. (via csv module)
* Optional alignment row (same trick as before) – keep it if you add one
* --delimiter   : any single‑character delimiter (default ',')
* --output      : path to write the Markdown table (default: stdout)
* Works on a file or on data piped from another program

Usage
-----
    # From a file, default delimiter
    $ ./csv_to_md.py data.csv > table.md

    # Use a semicolon as delimiter
    $ ./csv_to_md.py data.csv --delimiter ';' -o table.md

    # Read CSV from stdin, write to a file
    $ cat data.csv | ./csv_to_md.py --output table.md

    # Show help
    $ ./csv_to_md.py -h
"""

import argparse
import csv
import sys
from pathlib import Path
from typing import List, Iterable


# ----------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------
def _read_rows(source: Iterable[str], delim: str) -> List[List[str]]:
    """
    Parse CSV data from *source* (any iterable of strings) using *delim*.
    Empty rows are ignored.
    """
    reader = csv.reader(source, delimiter=delim)
    rows = [row for row in reader if any(cell.strip() for cell in row)]
    return rows


def _is_alignment_row(row: List[str]) -> bool:
    """
    Detect a Markdown alignment row (contains only ':' and/or '-' after stripping).
    """
    for cell in row:
        stripped = cell.strip()
        if stripped not in (":", "-", ":---:", ":-", "---", ":-)", ":---"):
            return False
    return True


def _make_markdown_table(data: List[List[str]]) -> str:
    """
    Convert the CSV *data* (header + optional rows) into a Markdown table.
    """
    if not data:
        return ""

    header = data[0]

    # Does a second row look like an alignment row?
    has_alignment = len(data) > 1 and _is_alignment_row(data[1])

    # ------------------------------------------------------------------
    # Build the separator line
    # ------------------------------------------------------------------
    if has_alignment:
        # Use whatever the user wrote in the alignment row.
        align_cells = data[1]
        sep_cells = []
        for i, cell in enumerate(align_cells):
            cell = cell.strip()
            # Width = max(3, header[i] width, any data cell width)
            col_width = max(3, len(header[i]))
            for r in data[2:]:
                if i < len(r):
                    col_width = max(col_width, len(r[i]))
            # Preserve leading / trailing ':' if present
            if cell.startswith(":") and cell.endswith(":"):
                sep_cells.append(f":{'-' * col_width}:")
            elif cell.startswith(":"):
                sep_cells.append(f"{cell}:{'-' * col_width}")
            elif cell.endswith(":"):
                sep_cells.append(f"{'-' * col_width}{cell}")
            else:
                sep_cells.append("-" * col_width)
        separator = " | ".join(sep_cells)
    else:
        separator = " | ".join("-" * max(3, len(col)) for col in header)

    # ------------------------------------------------------------------
    # Helper: pad a single data row to the correct column widths
    # ------------------------------------------------------------------
    def _pad(row: List[str]) -> str:
        # Ensure row length matches header length
        missing = len(header) - len(row)
        if missing:
            row = row + [""] * missing
        row = row[: len(header)]

        # Compute column widths (header vs. any data row)
        col_widths = []
        for i in range(len(header)):
            max_width = len(header[i])
            for r in data[1:]:
                if i < len(r):
                    max_width = max(max_width, len(r[i]))
            col_widths.append(max_width)

        # Build the padded line
        cells = [(row[i] if row[i] != "" else "") for i in range(len(header))]
        padded = " | ".join(
            f"{cells[i].ljust(col_widths[i])}" for i in range(len(header))
        )
        return padded

    # ------------------------------------------------------------------
    # Assemble final table
    # ------------------------------------------------------------------
    lines = [
        " | ".join(header),
        separator,
    ]
    start = 2 if has_alignment else 1
    for row in data[start:]:
        lines.append(_pad(row))

    return "\n".join(lines)


# ----------------------------------------------------------------------
# Main entry point
# ----------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a CSV file (or stdin) to a Markdown table."
    )
    parser.add_argument(
        "csv_file",
        nargs="?",
        type=Path,
        default=None,
        help="Path to the CSV file. If omitted, CSV data is read from stdin.",
    )
    parser.add_argument(
        "--delimiter",
        default=",",
        help="Field delimiter used in the CSV file (default: ','). Must be a single character.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Write the Markdown table to the given file. If omitted, prints to stdout.",
    )

    args = parser.parse_args()

    # Validate delimiter
    if len(args.delimiter) != 1:
        parser.error("The --delimiter option must be a single character.")

    # --------------------------------------------------------------
    # Choose the input source (file or stdin)
    # --------------------------------------------------------------
    if args.csv_file is None:
        # Reading from stdin; abort if nothing is piped
        if sys.stdin.isatty():
            parser.error(
                "No CSV file supplied and stdin is a terminal. "
                "Either provide a filename or pipe CSV data into the script."
            )
        source = sys.stdin
    else:
        if not args.csv_file.is_file():
            parser.error(f"File not found: {args.csv_file}")
        source = args.csv_file.open(newline="", encoding="utf-8")

    # --------------------------------------------------------------
    # Read CSV data
    # --------------------------------------------------------------
    with source:
        rows = _read_rows(source, delim=args.delimiter)

    if not rows:
        sys.stderr.write("Warning: No non‑empty rows were read from the input.\n")
        return

    # --------------------------------------------------------------
    # Build the Markdown table
    # --------------------------------------------------------------
    markdown_table = _make_markdown_table(rows)

    # --------------------------------------------------------------
    # Write the result
    # --------------------------------------------------------------
    if args.output:
        try:
            # Ensure parent directory exists (useful when user gives a nested path)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(markdown_table, encoding="utf-8")
        except OSError as exc:
            sys.stderr.write(f"Error writing to {args.output}: {exc}\n")
            sys.exit(1)
    else:
        # Print to stdout
        print(markdown_table)


if __name__ == "__main__":
    main()

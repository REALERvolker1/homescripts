#!/usr/bin/env python3
"""An interactive terminal stopwatch."""

import os
import select
import sys
import termios
import time
import tty


def format_elapsed(seconds: float) -> str:
    """Format elapsed seconds as hours, minutes, seconds, and centiseconds."""
    centiseconds = int(seconds * 100)
    total_seconds, hundredths = divmod(centiseconds, 100)
    total_minutes, seconds = divmod(total_seconds, 60)
    hours, minutes = divmod(total_minutes, 60)
    return f"{hours:02d}:{minutes:02d}:{seconds:02d}.{hundredths:02d}"


def run_stopwatch() -> None:
    """Run the stopwatch until q or Escape is pressed."""
    input_fd = sys.stdin.fileno()
    original_settings = termios.tcgetattr(input_fd)
    elapsed = 0.0
    started_at = 0.0
    running = False

    try:
        tty.setcbreak(input_fd)

        while True:
            now = time.monotonic()
            displayed = elapsed + (now - started_at if running else 0.0)
            status = "RUNNING" if running else "STOPPED"
            print(
                f"\r\033[2K{format_elapsed(displayed)}  [{status}]  "
                "Space: start/stop  q/Esc: exit",
                end="",
                flush=True,
            )

            readable, _, _ = select.select([input_fd], [], [], 0.03)
            if not readable:
                continue

            for key in os.read(input_fd, 32):
                if key in (ord("q"), ord("Q"), 0x1B):
                    return
                if key != ord(" "):
                    continue

                now = time.monotonic()
                if running:
                    elapsed += now - started_at
                    running = False
                else:
                    started_at = now
                    running = True
    finally:
        termios.tcsetattr(input_fd, termios.TCSADRAIN, original_settings)
        print()


def main() -> int:
    if not sys.stdin.isatty():
        print("stopwatch.py requires an interactive terminal", file=sys.stderr)
        return 1

    try:
        run_stopwatch()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

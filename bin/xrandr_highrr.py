#!/usr/bin/env python3

import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass


PRIMARY = "eDP-1"

# One of:
#   --left-of
#   --right-of
#   --above
#   --below
RELATIVE_POS = "--right-of"


@dataclass
class Mode:
	width: int
	height: int
	rate: float

	@property
	def name(self) -> str:
		return f"{self.width}x{self.height}"

	@property
	def pixels(self) -> int:
		return self.width * self.height


@dataclass
class Output:
	name: str
	modes: list[Mode]


def get_xrandr_outputs() -> list[Output]:
	"""Get connected outputs and all modes/rates advertised by RandR."""

	result = subprocess.run(
		["xrandr", "--query"],
		check=True,
		text=True,
		stdout=subprocess.PIPE,
	)

	outputs: list[Output] = []
	current: Output | None = None

	# Examples:
	#
	# HDMI-1-0 connected 1920x1080+1920+0 ...
	#
	#    1920x1080     239.96*+  144.00  120.00  60.00
	#    1680x1050      59.95
	#
	output_re = re.compile(r"^(\S+) connected(?:\s|$)")
	mode_re = re.compile(r"^\s+(\d+)x(\d+)\s+(.+)$")
	rate_re = re.compile(r"^(\d+(?:\.\d+)?)")

	for line in result.stdout.splitlines():
		output_match = output_re.match(line)

		if output_match:
			current = Output(output_match.group(1), [])
			outputs.append(current)
			continue

		# Any unindented line terminates the current output's mode list.
		if line and not line[0].isspace():
			current = None
			continue

		if current is None:
			continue

		mode_match = mode_re.match(line)
		if not mode_match:
			continue

		width = int(mode_match.group(1))
		height = int(mode_match.group(2))

		# Remaining fields are refresh rates, potentially decorated:
		#
		#   239.96*+
		#   144.00
		#   60.00+
		for token in mode_match.group(3).split():
			rate_match = rate_re.match(token)
			if rate_match:
				current.modes.append(
					Mode(
						width=width,
						height=height,
						rate=float(rate_match.group(1)),
					)
				)

	return outputs


def best_mode(output: Output) -> Mode:
	"""
	Prefer:
	    1. Highest resolution
	    2. Highest refresh rate at that resolution

	Resolution is ranked by total pixel count.
	"""

	if not output.modes:
		raise RuntimeError(f"No modes found for output {output.name!r}")

	return max(
		output.modes,
		key=lambda mode: (
			mode.pixels,
			mode.rate,
		),
	)


def main() -> int:
	dry_run = False

	if len(sys.argv) > 1:
		if sys.argv[1:] == ["--dry-run"]:
			dry_run = True
			print("dry run -- command will not run")
		else:
			print(
				f"""Usage: {sys.argv[0]} [--dry-run]

<no args>   run as usual
--dry-run   print the command but do not run
""",
				file=sys.stderr,
			)
			return 2

	if shutil.which("xrandr") is None:
		print("Error: xrandr is not installed", file=sys.stderr)
		return 1

	outputs = get_xrandr_outputs()

	if not outputs:
		print("Error: no connected monitors detected", file=sys.stderr)
		return 1

	output_by_name = {output.name: output for output in outputs}

	if PRIMARY not in output_by_name:
		print(
			f"Error: PRIMARY monitor {PRIMARY!r} not detected!",
			file=sys.stderr,
		)
		return 1

	selected: dict[str, Mode] = {}

	for output in outputs:
		mode = best_mode(output)
		selected[output.name] = mode

		extra = " -- $PRIMARY" if output.name == PRIMARY else ""

		print(f"detected monitor {output.name} -- {mode.name}@{mode.rate:g}Hz{extra}")

	#
	# Build:
	#
	# xrandr \
	#   --output eDP-1 --primary --mode 1920x1080 --rate 144 \
	#   --output HDMI-1-0 --mode 1920x1080 --rate 240 \
	#       --right-of eDP-1
	#
	command = ["xrandr"]

	primary_mode = selected[PRIMARY]

	command += [
		"--output",
		PRIMARY,
		"--primary",
		"--mode",
		primary_mode.name,
		"--rate",
		f"{primary_mode.rate:g}",
	]

	previous = PRIMARY

	for output in outputs:
		if output.name == PRIMARY:
			continue

		mode = selected[output.name]

		command += [
			"--output",
			output.name,
			"--mode",
			mode.name,
			"--rate",
			f"{mode.rate:g}",
			RELATIVE_POS,
			previous,
		]

		previous = output.name

	print()
	print(shlex.join(command))

	if not dry_run:
		subprocess.run(command, check=True)

		bg_script = shutil.which("vlkbg.sh")
		if bg_script:
			subprocess.Popen(
				[bg_script],
				start_new_session=True,
				stdout=subprocess.DEVNULL,
				stderr=subprocess.DEVNULL,
			)

	return 0


if __name__ == "__main__":
	raise SystemExit(main())

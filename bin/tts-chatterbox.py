#!/usr/bin/env python3
"""Small command-line frontend for Chatterbox TTS."""

from __future__ import annotations

import argparse
import logging
import os
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, TextIO

if TYPE_CHECKING:
	from torch import Tensor


# Importing this mapping from chatterbox also imports Torch and PerTh. Keep the
# small, stable CLI-facing mapping local so --help stays lightweight.
SUPPORTED_LANGUAGES = {
	"ar": "Arabic",
	"da": "Danish",
	"de": "German",
	"el": "Greek",
	"en": "English",
	"es": "Spanish",
	"fi": "Finnish",
	"fr": "French",
	"he": "Hebrew",
	"hi": "Hindi",
	"it": "Italian",
	"ja": "Japanese",
	"ko": "Korean",
	"ms": "Malay",
	"nl": "Dutch",
	"no": "Norwegian",
	"pl": "Polish",
	"pt": "Portuguese",
	"ru": "Russian",
	"sv": "Swedish",
	"sw": "Swahili",
	"tr": "Turkish",
	"zh": "Chinese",
}


def without_none(**values: object) -> dict[str, object]:
	"""Return keyword arguments explicitly overridden by the user."""
	return {name: value for name, value in values.items() if value is not None}


def resolve_device() -> str:
	"""Choose a Chatterbox-compatible device string."""
	requested = os.getenv("TORCH_DEVICE")
	if requested:
		logging.info("Using requested Torch device: %s", requested)
		return requested

	import torch

	if torch.cuda.is_available():
		logging.info("Using CUDA device")
		return "cuda"

	if torch.backends.mps.is_available():
		logging.info("Using MPS device")
		return "mps"

	logging.warning("Falling back to CPU")
	return "cpu"


@dataclass(frozen=True, slots=True)
class Generation:
	audio: Tensor
	sample_rate: int

	def channels_last(self) -> Tensor:
		"""Return float samples with the channel dimension last."""
		samples = self.audio.detach().cpu().float()
		if samples.ndim == 1:
			return samples
		if samples.ndim == 2:
			# Torch audio uses (channels, frames); playback and file-writing
			# libraries expect the channel dimension last.
			return samples.transpose(0, 1).contiguous()
		raise ValueError(
			f"Expected 1D or 2D audio tensor, got {tuple(samples.shape)}"
		)

	def save_as(self, output: Path) -> None:
		import soundfile as sf

		sf.write(
			file=output,
			data=self.channels_last().numpy(),
			samplerate=self.sample_rate,
		)

	def play(self) -> None:
		import sounddevice as sd

		sd.play(
			self.channels_last().numpy(),
			samplerate=self.sample_rate,
			blocking=True,
		)


@dataclass(slots=True)
class GenerationConfig:
	"""User-specified generation options shared by the model backends."""

	device: str
	audio_prompt: Path | None = None

	# None preserves each backend's own default instead of duplicating it here.
	repetition_penalty: float | None = None
	min_p: float | None = None
	top_p: float | None = None
	exaggeration: float | None = None
	cfg_weight: float | None = None
	temperature: float | None = None

	# Turbo-specific options.
	norm_loudness: bool | None = None
	top_k: int | None = None

	def tts_regular(self, text: str) -> Generation:
		import chatterbox.tts

		model = chatterbox.tts.ChatterboxTTS.from_pretrained(device=self.device)
		kwargs = without_none(
			audio_prompt_path=self.audio_prompt,
			repetition_penalty=self.repetition_penalty,
			min_p=self.min_p,
			top_p=self.top_p,
			exaggeration=self.exaggeration,
			cfg_weight=self.cfg_weight,
			temperature=self.temperature,
		)
		audio = model.generate(text=text, **kwargs)
		return Generation(audio=audio, sample_rate=model.sr)

	def tts_multilingual(self, text: str, language: str) -> Generation:
		import chatterbox.mtl_tts

		# chatterbox-tts 0.1.7 only provides the V2 multilingual checkpoint;
		# its loader does not accept the newer t3_model argument.
		model = chatterbox.mtl_tts.ChatterboxMultilingualTTS.from_pretrained(
			device=self.device
		)
		kwargs = without_none(
			audio_prompt_path=self.audio_prompt,
			repetition_penalty=self.repetition_penalty,
			min_p=self.min_p,
			top_p=self.top_p,
			exaggeration=self.exaggeration,
			cfg_weight=self.cfg_weight,
			temperature=self.temperature,
		)
		audio = model.generate(text=text, language_id=language, **kwargs)
		return Generation(audio=audio, sample_rate=model.sr)

	def tts_turbo(self, text: str) -> Generation:
		try:
			import chatterbox.tts_turbo
		except ModuleNotFoundError as error:
			if error.name == "future":
				raise SystemExit(
					"Turbo backend is unavailable: the installed pyloudnorm "
					"package requires the missing 'future' package"
				) from None
			raise

		model = chatterbox.tts_turbo.ChatterboxTurboTTS.from_pretrained(
			device=self.device
		)
		kwargs = without_none(
			audio_prompt_path=self.audio_prompt,
			repetition_penalty=self.repetition_penalty,
			top_p=self.top_p,
			temperature=self.temperature,
			top_k=self.top_k,
			norm_loudness=self.norm_loudness,
		)
		audio = model.generate(text=text, **kwargs)
		return Generation(audio=audio, sample_rate=model.sr)


def read_text(
	parser: argparse.ArgumentParser,
	literal: str | None,
	input_file: Path | None,
	stdin: TextIO,
) -> str:
	"""Read text from the explicitly selected source or piped stdin."""
	if literal is not None and input_file is not None:
		parser.error("Text and --input cannot be used together")

	try:
		if input_file == Path("-"):
			text = stdin.read()
		elif input_file is not None:
			text = input_file.read_text(encoding="utf-8")
		elif literal is not None:
			text = literal
		elif not stdin.isatty():
			text = stdin.read()
		else:
			parser.error("Nothing to say; provide text, --input FILE, or piped stdin")
	except (OSError, UnicodeError) as error:
		source = "stdin" if input_file == Path("-") or input_file is None else input_file
		parser.error(f"Could not read text from {source}: {error}")

	if not text.strip():
		parser.error("Nothing to say; the text input is empty")
	return text


def build_parser() -> argparse.ArgumentParser:
	parser = argparse.ArgumentParser(
		description="Make the computer say something",
		formatter_class=argparse.ArgumentDefaultsHelpFormatter,
	)
	parser.add_argument(
		"-o",
		"--output",
		type=Path,
		help=(
			"Write audio instead of playing it. The extension selects the format; "
			"common formats are WAV, FLAC, OGG/Vorbis, MP3, AIFF, AU, and CAF"
		),
	)
	parser.add_argument(
		"-l",
		"--language",
		choices=SUPPORTED_LANGUAGES,
		metavar="CODE",
		help="Use the multilingual model with this ISO language code",
	)
	parser.add_argument(
		"--list-languages",
		action="store_true",
		help="List the available multilingual TTS languages and exit",
	)
	parser.add_argument(
		"--use-turbo",
		action="store_true",
		help=(
			"Use the lower-compute, English-only Turbo model, which supports "
			"[cough], [laugh], and [chuckle] tokens"
		),
	)
	parser.add_argument(
		"--audio-prompt-path",
		"--audio_prompt_path",
		dest="audio_prompt_path",
		type=Path,
		help=(
			"Voice clip to clone. Supports libsndfile formats, including WAV, "
			"FLAC, OGG/Vorbis, MP3, AIFF, AU, and CAF"
		),
	)
	parser.add_argument(
		"-i",
		"--input",
		type=Path,
		metavar="FILE",
		help="Read UTF-8 text from FILE; use - for stdin",
	)
	# This is optional so --list-languages and piped stdin work without it.
	parser.add_argument("text", nargs="?", help="Literal text to say")
	return parser


def configure_logging() -> None:
	log_level = os.getenv("LOG_LEVEL", "INFO").upper()
	try:
		logging.basicConfig(level=log_level)
	except ValueError:
		raise SystemExit(f"Invalid LOG_LEVEL: {log_level!r}") from None


def main(argv: Sequence[str] | None = None) -> int:
	configure_logging()
	parser = build_parser()
	args = parser.parse_args(argv)

	if args.list_languages:
		for code, name in SUPPORTED_LANGUAGES.items():
			print(f"{code} ({name})")
		return 0

	text = read_text(parser, args.text, args.input, sys.stdin)

	if args.use_turbo and args.language is not None:
		parser.error("--use-turbo cannot be combined with --language")

	output_file: Path | None = args.output
	if output_file is not None and output_file.exists():
		parser.error(f"Output file already exists: {output_file}")

	audio_prompt: Path | None = args.audio_prompt_path
	if audio_prompt is not None and not audio_prompt.is_file():
		parser.error(f"Audio prompt is not a regular file: {audio_prompt}")

	config = GenerationConfig(
		device=resolve_device(),
		audio_prompt=audio_prompt,
	)
	if audio_prompt is not None:
		logging.info("Cloning voice from clip: %s", audio_prompt)

	if args.use_turbo:
		logging.info("Using Turbo English model")
		output = config.tts_turbo(text)
	elif args.language is not None:
		logging.info(
			"Using multilingual model for %s", SUPPORTED_LANGUAGES[args.language]
		)
		output = config.tts_multilingual(text, language=args.language)
	else:
		logging.info("Using regular English model")
		output = config.tts_regular(text)

	if output_file is not None:
		logging.info("Writing speech to file: %s", output_file)
		output.save_as(output_file)
	else:
		logging.info("Playing speech")
		output.play()

	return 0


if __name__ == "__main__":
	raise SystemExit(main())

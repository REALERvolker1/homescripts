#!/usr/bin/env python3
"""Small command-line frontend for Chatterbox TTS."""

from __future__ import annotations

import argparse
import logging
import os
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING

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

	def save_as(self, output: Path) -> None:
		import torchaudio

		torchaudio.save(
			uri=str(output),
			src=self.audio.detach().cpu(),
			sample_rate=self.sample_rate,
		)

	def play(self) -> None:
		import sounddevice as sd

		samples = self.audio.detach().cpu().float()
		if samples.ndim == 1:
			playback = samples
		elif samples.ndim == 2:
			# Torch audio uses (channels, frames); sounddevice expects the
			# channel dimension last.
			playback = samples.transpose(0, 1).contiguous()
		else:
			raise ValueError(
				f"Expected 1D or 2D audio tensor, got {tuple(samples.shape)}"
			)

		sd.play(
			playback.numpy(),
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


def build_parser() -> argparse.ArgumentParser:
	parser = argparse.ArgumentParser(
		description="Make the computer say something",
		formatter_class=argparse.ArgumentDefaultsHelpFormatter,
	)
	parser.add_argument(
		"-o",
		"--output",
		type=Path,
		help="File to write; if omitted, play the generated audio",
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
		help="A voice clip to clone",
	)
	# This is optional only so --list-languages can be used on its own. main()
	# requires it for every generation mode.
	parser.add_argument("text", nargs="?", help="What to say")
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

	if not args.text:
		parser.error("Nothing to say; provide text")

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
		output = config.tts_turbo(args.text)
	elif args.language is not None:
		logging.info(
			"Using multilingual model for %s", SUPPORTED_LANGUAGES[args.language]
		)
		output = config.tts_multilingual(args.text, language=args.language)
	else:
		logging.info("Using regular English model")
		output = config.tts_regular(args.text)

	if output_file is not None:
		logging.info("Writing speech to file: %s", output_file)
		output.save_as(output_file)
	else:
		logging.info("Playing speech")
		output.play()

	return 0


if __name__ == "__main__":
	raise SystemExit(main())

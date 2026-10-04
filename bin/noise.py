#!/usr/bin/env python3
"""Create an RGB PNG filled with independent random channel values."""

import argparse
import secrets
import struct
import zlib
from pathlib import Path


def positive_int(value: str) -> int:
    """Parse a positive integer for an image dimension."""
    try:
        number = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("must be an integer") from error
    if number <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return number


def png_chunk(kind: bytes, data: bytes) -> bytes:
    """Encode a PNG chunk, including its length and CRC."""
    chunk_data = kind + data
    return struct.pack(">I", len(data)) + chunk_data + struct.pack(">I", zlib.crc32(chunk_data))


def create_noise_image(width: int, height: int, output: Path) -> None:
    """Write an RGB PNG whose red, green, and blue bytes are random."""
    scanlines = bytearray()
    for _ in range(height):
        scanlines.append(0)  # PNG filter type 0: no filtering.
        scanlines.extend(secrets.token_bytes(width * 3))

    image = (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(scanlines))
        + png_chunk(b"IEND", b"")
    )
    output.write_bytes(image)


def main() -> None:
    parser = argparse.ArgumentParser(description="Create an RGB random-noise PNG.")
    parser.add_argument("width", type=positive_int)
    parser.add_argument("height", type=positive_int)
    parser.add_argument("image", type=Path, help="output PNG path")
    args = parser.parse_args()
    create_noise_image(args.width, args.height, args.image)


if __name__ == "__main__":
    main()

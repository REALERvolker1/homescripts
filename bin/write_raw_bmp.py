#!/usr/bin/env python3
# a one-off script, do not use lol

import sys
from pathlib import Path

IMAGE_PATH = Path("/home/vlk/Documents/rgb565_gradient16bit.bmp")

FIVEBIT = 0b00_01_11_11
SIXBIT = 0b00_11_11_11

type ExitCode = int

EXIT_INVALID_FILE: ExitCode = 1
EXIT_INVALID_BITMAP: ExitCode = 2
EXIT_INVALID_COLOR_DEPTH: ExitCode = 3

type ByteAddress = int
COLOR_DEPTH_ADDR_BEGIN: ByteAddress = 0x1C
COLOR_DEPTH_ADDR_END: ByteAddress = 0x1E

FILE_SIZE_ADDR_BEGIN: ByteAddress = 0x02
FILE_SIZE_ADDR_END: ByteAddress = 0x06

DATA_OFFSET_ADDR_BEGIN: ByteAddress = 0x0A
DATA_OFFSET_ADDR_END: ByteAddress = 0x0E

DATA_SIZE_ADDR_BEGIN: ByteAddress = 0x22
DATA_SIZE_ADDR_END: ByteAddress = 0x26

WIDTH_ADDR_BEGIN: ByteAddress = 0x12
WIDTH_ADDR_END: ByteAddress = 0x16

HEIGHT_ADDR_BEGIN: ByteAddress = WIDTH_ADDR_END
HEIGHT_ADDR_END: ByteAddress = 0x1A

COMPRESSION_ADDR_BEGIN: ByteAddress = 0x1E
COMPRESSION_ADDR_END: ByteAddress = 0x22

PPM_ADDR_BEGIN: ByteAddress = 0x26
PPM_ADDR_END: ByteAddress = 0x2E

# These are known constants I guess
UNIVERSAL_HEADER_SIZE = 14
WINDOWS_HEADER_SIZE = 40

# The 5-6-5 color bitfield, as little-endian bytes
FIVESIXFIVE_COLOR_BITFIELD = [0, 0xF8, 0, 0, 0xE0, 0x07, 0, 0, 0x1F, 0, 0, 0]

image_bytes = bytearray()
for byte in IMAGE_PATH.read_bytes():
    image_bytes.append(byte)

data_offset = int.from_bytes(image_bytes[DATA_OFFSET_ADDR_BEGIN:DATA_OFFSET_ADDR_END], byteorder="little", signed = False)
data_size = int.from_bytes(image_bytes[DATA_SIZE_ADDR_BEGIN:DATA_SIZE_ADDR_END], byteorder="little", signed = False)

counter = 0x0000;
index = data_offset
end = data_size + data_offset
while data_offset < end:
    image_bytes[data_offset + 1] = (counter >> 8) & 0xFF
    image_bytes[data_offset] = counter & 0xFF

    counter += 1
    if counter > 0xFFFF:
        counter = 0

    data_offset += 2

IMAGE_PATH.write_bytes(image_bytes)

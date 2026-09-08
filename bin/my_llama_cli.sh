#!/usr/bin/env bash
set -euo pipefail

: "${LLAMA_RAM_PERCENT:=66}" "${LLAMA_CTX_CAP:=384000}"

usage() {
	echo "Usage: $0 MODEL.gguf [llama-cli args...]" >&2
	exit 2
}

[[ $# -ge 1 ]] || usage

MODEL=$1
shift

[[ -f "$MODEL" ]] || {
	echo "error: model not found: $MODEL" >&2
	exit 2
}

[[ "$RAM_PERCENT" =~ ^[0-9]+$ ]] &&
	((RAM_PERCENT >= 1 && RAM_PERCENT <= 100)) || {
	echo "error: MY_LLAMA_RAM_PERCENT must be an integer from 1 to 100" >&2
	exit 2
}

#
# Find llama-cli.
#
# Override with:
#
#   LLAMA_CLI=/wherever/llama-cli ./my_llama_cli.sh model.gguf
#

if [[ -n "${LLAMA_CLI:-}" ]]; then
	CLI=$LLAMA_CLI
elif command -v llama-cli >/dev/null 2>&1; then
	CLI=$(command -v llama-cli)
elif [[ -x ./bin/llama-cli ]]; then
	CLI=./bin/llama-cli
elif [[ -x ./build/bin/llama-cli ]]; then
	CLI=./build/bin/llama-cli
elif [[ -x ./llama-cli ]]; then
	CLI=./llama-cli
else
	echo "error: llama-cli not found" >&2
	echo "       set LLAMA_CLI=/path/to/llama-cli" >&2
	exit 127
fi

#
# Read *.context_length directly from the GGUF header.
#
# This does NOT load the tensors and doesn't require the Python gguf package.
# It only requires python3.
#

read_gguf_context() {
	python3 - "$1" <<'PY'
import struct
import sys

path = sys.argv[1]

# GGUF metadata value type sizes.
SIZES = {
    0: 1,   # UINT8
    1: 1,   # INT8
    2: 2,   # UINT16
    3: 2,   # INT16
    4: 4,   # UINT32
    5: 4,   # INT32
    6: 4,   # FLOAT32
    7: 1,   # BOOL
    10: 8,  # UINT64
    11: 8,  # INT64
    12: 8,  # FLOAT64
}

INT_TYPES = {0, 1, 2, 3, 4, 5, 10, 11}

with open(path, "rb", buffering=0) as f:
    if f.read(4) != b"GGUF":
        raise SystemExit(1)

    raw_version = f.read(4)

    le_version = struct.unpack("<I", raw_version)[0]
    be_version = struct.unpack(">I", raw_version)[0]

    if 1 <= le_version <= 3:
        endian = "<"
    elif 1 <= be_version <= 3:
        endian = ">"
    else:
        raise SystemExit(1)

    def unpack(fmt):
        size = struct.calcsize(fmt)
        data = f.read(size)

        if len(data) != size:
            raise EOFError

        return struct.unpack(endian + fmt, data)[0]

    def read_string():
        n = unpack("Q")
        data = f.read(n)

        if len(data) != n:
            raise EOFError

        return data.decode("utf-8", "replace")

    def skip_value(t):
        if t in SIZES:
            f.seek(SIZES[t], 1)

        elif t == 8:  # STRING
            n = unpack("Q")
            f.seek(n, 1)

        elif t == 9:  # ARRAY
            item_t = unpack("I")
            n = unpack("Q")

            if item_t in SIZES:
                f.seek(SIZES[item_t] * n, 1)

            elif item_t == 8:
                for _ in range(n):
                    length = unpack("Q")
                    f.seek(length, 1)

            else:
                for _ in range(n):
                    skip_value(item_t)

        else:
            raise ValueError(f"unknown GGUF value type {t}")

    def read_scalar(t):
        fmts = {
            0: "B",
            1: "b",
            2: "H",
            3: "h",
            4: "I",
            5: "i",
            6: "f",
            7: "B",
            10: "Q",
            11: "q",
            12: "d",
        }

        return unpack(fmts[t])

    # Header
    _tensor_count = unpack("Q")
    kv_count = unpack("Q")

    architecture = None
    candidates = []

    for _ in range(kv_count):
        key = read_string()
        value_type = unpack("I")

        if key == "general.architecture" and value_type == 8:
            architecture = read_string()
            continue

        if key.endswith(".context_length") and value_type in INT_TYPES:
            value = int(read_scalar(value_type))

            if value > 0:
                if (
                    architecture
                    and key == f"{architecture}.context_length"
                ):
                    print(value)
                    raise SystemExit(0)

                candidates.append((key, value))

            continue

        skip_value(value_type)

    # Fallback if architecture appeared after the context field.
    if architecture:
        wanted = f"{architecture}.context_length"

        for key, value in candidates:
            if key == wanted:
                print(value)
                raise SystemExit(0)

    # A single context_length is unambiguous enough.
    if len(candidates) == 1:
        print(candidates[0][1])
        raise SystemExit(0)

raise SystemExit(1)
PY
}

#
# Context policy.
#
# Explicit OLLAMA_CONTEXT_LENGTH wins.
#
# Otherwise:
#     native model context, capped at 384k
#

CTX_SOURCE=""

if [[ "${OLLAMA_CONTEXT_LENGTH:-}" =~ ^[0-9]+$ ]]; then

	CTX=$OLLAMA_CONTEXT_LENGTH
	CTX_SOURCE="OLLAMA_CONTEXT_LENGTH"

else
	if [[ -n "${OLLAMA_CONTEXT_LENGTH:-}" &&
		"${OLLAMA_CONTEXT_LENGTH:-}" != "0" ]]; then

		echo \
			"warning: ignoring invalid OLLAMA_CONTEXT_LENGTH=${OLLAMA_CONTEXT_LENGTH@Q}" \
			>&2
	fi

	if NATIVE_CTX=$(read_gguf_context "$MODEL" 2>/dev/null); then

		if ((NATIVE_CTX > CTX_CAP)); then
			CTX=$CTX_CAP
			CTX_SOURCE="GGUF native ${NATIVE_CTX}, capped"
		else
			CTX=$NATIVE_CTX
			CTX_SOURCE="GGUF native"
		fi

	else
		#
		# If some weird future GGUF defeats our tiny parser,
		# fall back to llama.cpp's native context behavior.
		#
		CTX=0
		CTX_SOURCE="llama.cpp native fallback (metadata parse failed)"
	fi
fi

#
# Calculate total GGUF size.
#
# Handles ordinary single-file models and standard split names:
#
#   Model-Q4_K_M-00001-of-00003.gguf
#   Model-Q4_K_M-00002-of-00003.gguf
#   Model-Q4_K_M-00003-of-00003.gguf
#

model_size_bytes() {
	local model=$1
	local dir base stem count i shard total=0

	dir=$(dirname -- "$model")
	base=$(basename -- "$model")

	if [[ "$base" =~ ^(.*)-([0-9]{5})-of-([0-9]{5})\.gguf$ ]]; then

		stem=${BASH_REMATCH[1]}
		count=$((10#${BASH_REMATCH[3]}))

		for ((i = 1; i <= count; i++)); do
			printf -v shard \
				'%s/%s-%05d-of-%05d.gguf' \
				"$dir" "$stem" "$i" "$count"

			if [[ ! -f "$shard" ]]; then
				echo \
					"warning: split model shard missing: $shard" \
					>&2

				stat -Lc '%s' -- "$model"
				return
			fi

			((total += $(stat -Lc '%s' -- "$shard")))
		done

		echo "$total"

	else
		stat -Lc '%s' -- "$model"
	fi
}

MODEL_BYTES=$(model_size_bytes "$MODEL")

#
# Linux MemAvailable is exactly the quantity we care about here:
# memory the kernel believes can currently be used without getting
# into serious swapping pressure.
#

MEM_AVAILABLE_KIB=$(
	awk '/^MemAvailable:/ {print $2; exit}' /proc/meminfo
)

[[ -n "$MEM_AVAILABLE_KIB" ]] || {
	echo "error: could not read MemAvailable from /proc/meminfo" >&2
	exit 1
}

MEM_AVAILABLE_BYTES=$((MEM_AVAILABLE_KIB * 1024))
RAM_BUDGET_BYTES=$((MEM_AVAILABLE_BYTES * RAM_PERCENT / 100))

#
# RAM / mmap policy.
#
# If the *entire* GGUF fits in the RAM allowance, non-mmap loading is
# comfortably safe.
#
# Otherwise mmap it and let Linux reclaim file-backed pages as necessary.
#

if ((MODEL_BYTES <= RAM_BUDGET_BYTES)); then

	LOAD_MODE=none
	LOAD_REASON="GGUF fits inside ${RAM_PERCENT}% of MemAvailable"

else

	LOAD_MODE=mmap
	LOAD_REASON="GGUF exceeds ${RAM_PERCENT}% of MemAvailable"

fi

human_bytes() {
	if command -v numfmt >/dev/null 2>&1; then
		numfmt --to=iec-i --suffix=B "$1"
	else
		echo "$1 bytes"
	fi
}

#
# Tell us what policy was chosen before launching.
#

printf \
	'[my_llama_cli] model:       %s (%s)\n' \
	"$MODEL" "$(human_bytes "$MODEL_BYTES")" \
	>&2

printf \
	'[my_llama_cli] context:     %s (%s)\n' \
	"$CTX" "$CTX_SOURCE" \
	>&2

printf \
	'[my_llama_cli] RAM avail:   %s; budget: %s (%s%%)\n' \
	"$(human_bytes "$MEM_AVAILABLE_BYTES")" \
	"$(human_bytes "$RAM_BUDGET_BYTES")" \
	"$RAM_PERCENT" \
	>&2

printf \
	'[my_llama_cli] load mode:   %s (%s)\n' \
	"$LOAD_MODE" "$LOAD_REASON" \
	>&2

printf \
	'[my_llama_cli] GPU fitting: llama.cpp auto/default\n' \
	>&2

#
# Current llama.cpp defaults do the remaining interesting work:
#
#   --gpu-layers auto
#   --fit on
#   --fit-target 1024
#   --flash-attn auto
#   --kv-offload
#
# User-supplied llama-cli arguments are forwarded unchanged.
#

exec "$CLI" \
	--model "$MODEL" \
	--ctx-size "$CTX" \
	--load-mode "$LOAD_MODE" \
	"$@"

#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob dotglob
IFS=$'\n\t'

ME="${0##*/}"
MYSTTY="$(stty -g)"

: "${EPHEMERAL_DISTRO:=docker.io/library/debian:latest}" "${EPHEMERAL_PORT:=8000}" "${HOST_BACKDOOR_PORT:=8001}" "${EPHEMERAL_BACKDOOR_DIR:=/backdoor}"

declare -i made_temp=0
declare -i tmpdel_threshold=0

__cleanup() {
    if [[ -t 0 ]]; then
        stty "$MYSTTY"
    fi
    if ((made_temp)); then
        local -a tmps
        tmps=("$HOST_BACKDOOR_DIR"/*)
        if ((${#tmps[@]} > tmpdel_threshold)); then
            ls -AlhF --color=auto "$HOST_BACKDOOR_DIR"
            printf 'Removing tmpdir %q in %s seconds, press Ctrl-C to abort...\n' "$HOST_BACKDOOR_DIR" "${HOST_BACKDOOR_DIR_CLEANUP_TIMER:=5}"
            sleep "$HOST_BACKDOOR_DIR_CLEANUP_TIMER"
        fi
        rm -rf "$HOST_BACKDOOR_DIR"
    fi
}

trap __cleanup EXIT

if [[ -z ${HOST_BACKDOOR_DIR-} ]]; then
    made_temp=1
    HOST_BACKDOOR_DIR="$(mktemp -d "${XDG_RUNTIME_DIR:-"${TMP:=/tmp}"}/${ME%%.*}XXXXX")"
    printf 'Made shared tempdir: %q => %q\n' "$HOST_BACKDOOR_DIR" "$EPHEMERAL_BACKDOOR_DIR"
else
    printf 'Custom backdoor dir: %q\n' "$HOST_BACKDOOR_DIR"
fi

if [[ -z ${PODMAN-} ]]; then
    for i in podman docker; do
        if hash "$i"; then
            PODMAN="$i"
            break
        fi
    done

fi
if [[ -z ${PODMAN-} ]]; then
    echo 'No container runtime found'
    exit 1
fi

declare -a docker_args=("$PODMAN" run --rm -it)

if (($# == 0)); then
    declare -a rcfile=()
    if ((made_temp)); then
        rcfile+=(--rcfile "$EPHEMERAL_BACKDOOR_DIR/shrc")
        tmpdel_threshold=$((tmpdel_threshold + 1))

        if [[ -n ${MINIMAL_SHRC-} ]]; then
            printf '%s\n' "$MINIMAL_SHRC" >"$HOST_BACKDOOR_DIR/shrc"
        else
            cat >"$HOST_BACKDOOR_DIR/shrc" <<EOF
alias ls='ls -AshF --color=auto'
alias ll='ls -AlhF --color=auto'
alias grep='grep --color=auto'
alias q=exit
alias wq=exit
alias -- -='cd -'
EOF
        fi
    fi

    set -- bash "${rcfile[@]}" -O autocd -O dotglob -O failglob
fi

docker_args+=(
    # -p "$HOST_BACKDOOR_PORT:$EPHEMERAL_PORT"
    -v "$HOST_BACKDOOR_DIR:$EPHEMERAL_BACKDOOR_DIR"
    "$EPHEMERAL_DISTRO"
    "$@"
)

printf '%q ' "${docker_args[@]}"
printf '\n'

"${docker_args[@]}"

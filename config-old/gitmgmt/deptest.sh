#!/usr/bin/bash

if ! grep -q '^NAME="Fedora.*"$' /etc/os-release; then
    echo "Error, you must run this script on Fedora Linux!"
    exit 1
fi


if ! sudo -vn &>/dev/null; then
    echo -n "This script requires sudo. Care to proceed? [y/N] "
    read answer
    [[ "$answer" == 'y' ]] || exit 1
fi

# make sure we have docker
rpm -q moby-engine &>/dev/null || sudo dnf install moby-engine

fedora="$(rpm -E %fedora)"
container="fedora:${fedora}"

basepkgs="git"

sudo docker pull "$container"

sudo docker run -ti "$container" bash -c "dnf update -y; dnf install $basepkgs -y; bash -i"

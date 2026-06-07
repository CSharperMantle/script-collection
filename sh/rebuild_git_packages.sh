#!/bin/bash

set -u

aurdir=/home/csmantle/dist/aur

mapfile -t packages < <(find "$aurdir" -maxdepth 1 -type d -name '*-git' -printf '%f\n' | sort)

declare -A _paru_flags=(
	# eg. ['package-git']='--nocheck'
)

declare -A _env_overrides=(
	# eg. ['package-git']='MAKEFLAGS="-j2"'
)

echo 'Acquiring root token ...'
sudo -v
while true; do
	sudo -n -v 2>/dev/null
	sleep 60
done &
sudo_keepalive_pid=$!
trap 'kill $sudo_keepalive_pid 2>/dev/null' EXIT

echo 'Rebuilding -git packages ...'
for p in "${packages[@]}"; do
	pacman -Q "$p" &>/dev/null || continue
	printf 'Building %s ...\n' "$p"
	(
		cd "$aurdir"/"$p" || exit 2
		# shellcheck disable=SC2086
		env MAKEFLAGS="-j $(nproc)" ${_env_overrides[$p]:-} nice -n 15 -- \
			paru -B -i --noconfirm --needed ${_paru_flags[$p]:-} .
	)
done

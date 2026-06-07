#!/bin/bash

set -eu

aurdir=/home/csmantle/dist/aur
packages=(
	'folly'
	'fizz'
	'mvfst'
	'wangle'
	'fbthrift'
	'fb303'
	'edencommon'
	'watchman'
)

bump_pkgrel() {
	cd "$1"

	local old_pkgrel new_pkgrel
	old_pkgrel="$(grep -Po '^pkgrel=\K[0-9]+' PKGBUILD)"
	new_pkgrel=$((old_pkgrel + 1))

	sed -i "s/^pkgrel=[0-9]\+/pkgrel=$new_pkgrel/" PKGBUILD
	makepkg --printsrcinfo > .SRCINFO
}

echo 'Verifying version sanity ...'
versions=()
for p in "${packages[@]}"; do
	versions+=("$(cat "$aurdir"/"$p"/PKGBUILD | grep -iF 'pkgver=' | cut --delimiter='=' -f 2 | sort -u)")
done
IFS=$'\n' read -r -a versions <<< "$( printf '%s\n' "${versions[@]}" | sort -u )"
if [ "${#versions[@]}" -ne 1 ]; then
	echo 'Conflicting versions:'
	printf '%s\n' "${versions[@]}"
	exit 2
fi

echo 'Acquiring root token ...'
sudo -v
while true; do
	sudo -n -v 2>/dev/null
	sleep 60
done &
sudo_keepalive_pid=$!
trap 'kill $sudo_keepalive_pid 2>/dev/null' EXIT

echo 'Rebuilding the watchman family ...'
for p in "${packages[@]}"; do
	printf 'Bumping pkgrel for %s ...\n' "$p"
	bump_pkgrel "$aurdir"/"$p"

	printf 'Building %s ...\n' "$p"
	paru --noconfirm -i -B "$aurdir"/"$p"
done

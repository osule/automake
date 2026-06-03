#!/usr/bin/env bash

# Shared helpers for the automake plugin.
#
# Versions are listed from the upstream git tags at autotools-mirror/automake,
# and built from the official GNU release tarballs (which ship a pre-generated
# ./configure). Building automake requires autoconf and perl.

set -euo pipefail

GH_REPO="https://github.com/autotools-mirror/automake"
GNU_MIRROR="${GNU_MIRROR:-https://ftp.gnu.org/gnu}"
TOOL_NAME="automake"
MAIN_BIN="automake"
TOOL_TEST="automake --version"
ARCHIVE_EXT="tar.xz"
# automake needs autoconf (provide it via autoconf or your package manager).
BUILD_DEPS="autoconf perl make"
CONFIGURE_OPTIONS="${AUTOMAKE_CONFIGURE_OPTIONS:-}"

fail() {
	echo -e "$TOOL_NAME: $*" >&2
	exit 1
}

# Versions are listed via `git ls-remote` and tarballs come from the GNU mirror,
# so no GitHub API requests are made and no token is needed.
curl_opts=(-fsSL)

sort_versions() {
	sed 'h; s/[+-]/./g; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3-
}

# Stable releases only. Development snapshots use a trailing letter (1.16i) or
# a >= .90 patch level (1.16.90); neither is published on the GNU mirror.
list_all_versions() {
	list_github_tags |
		sed 's/^v//' |
		grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' |
		awk -F. '$NF < 90 { print }' |
		sort_versions
}

release_url() {
	echo "$GNU_MIRROR/$TOOL_NAME/$TOOL_NAME-$1.$ARCHIVE_EXT"
}

download_and_extract() {
	local version="$1"
	local dest="$2"
	local url filename
	url="$(release_url "$version")"
	filename="$dest/$TOOL_NAME-$version.$ARCHIVE_EXT"

	mkdir -p "$dest"
	echo "* Downloading $TOOL_NAME $version from $url ..."
	curl "${curl_opts[@]}" -o "$filename" "$url" || fail "Could not download $url"

	echo "* Extracting ..."
	tar -xf "$filename" -C "$dest" --strip-components=1 || fail "Could not extract $filename"
	rm -f "$filename"
}

check_build_deps() {
	local missing=()
	local cmd
	for cmd in $BUILD_DEPS; do
		command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
	done
	if [ "${#missing[@]}" -gt 0 ]; then
		fail "Missing build dependencies: ${missing[*]}\n$(deps_hint)"
	fi
}

deps_hint() {
	cat <<-EOF
		automake needs autoconf, perl and make. Install autoconf first, e.g.:
		  asdf:         asdf plugin add autoconf && asdf install autoconf latest \\
		                  && asdf global autoconf latest && asdf reshim
		  macOS:        brew install autoconf automake perl
		  Debian/Ubuntu: sudo apt-get install autoconf perl make
	EOF
}

build_and_install() {
	local version="$1"
	local install_path="$2"
	local src="${ASDF_DOWNLOAD_PATH:-}"

	check_build_deps
	[ -n "$src" ] && [ -f "$src/configure" ] ||
		fail "No ./configure in source ('$src'); was bin/download run?"

	# NOTE: `set -e` is suppressed inside a subshell on the left of `|| fail`,
	# so each step needs an explicit `|| exit 1` — otherwise a failed
	# ./configure would fall through to `make` and emit confusing errors.
	(
		cd "$src" || exit 1
		echo "* Configuring ..."
		# shellcheck disable=SC2086
		./configure --prefix="$install_path" $CONFIGURE_OPTIONS || exit 1
		echo "* Building ..."
		make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)" || exit 1
		echo "* Installing into $install_path ..."
		make install || exit 1
	) || fail "Build/install of $TOOL_NAME $version failed."

	test -x "$install_path/bin/$MAIN_BIN" ||
		fail "Expected $install_path/bin/$MAIN_BIN to exist after install."
	(
		export PATH="$install_path/bin:$PATH"
		eval "$TOOL_TEST"
	) >/dev/null || fail "Installed $TOOL_NAME failed its smoke test ($TOOL_TEST)."

	echo "* $TOOL_NAME $version installed successfully."
}

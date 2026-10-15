#!/usr/bin/env bash
set -e

# Determine directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR"
SRC="$ROOT/src"
BUILD="$ROOT/dist"
THEME="WhiteSur Cursors"

# check command availability
has_command() {
	command -v "$1" >/dev/null 2>&1
}

# Dependency checks
check_dependencies() {
	local missing=()

	if ! has_command xcursorgen; then
		missing+=("xorg-xcursorgen (or x11-apps)")
	fi
	if ! has_command rsvg-convert; then
		missing+=("librsvg2-bin (rsvg-convert)")
	fi
	if ! has_command python3; then
		missing+=("python3")
	fi

	if [ ${#missing[@]} -ne 0 ]; then
		echo "Warning: The following dependencies are required to build cursors from source:"
		for dep in "${missing[@]}"; do
			echo "  - $dep"
		done
		echo ""
		echo "On Kali Linux / Debian / Ubuntu, install with:"
		echo "  sudo apt install -y xorg-xcursorgen librsvg2-bin python3 git"
		echo ""

		# If apt-get is available and running with sudo/root or terminal prompt, offer prompt
		if [ -t 0 ] && has_command apt-get; then
			read -r -p "Attempt to install missing packages now with sudo? [y/N] " response
			if [[ "$response" =~ ^[Yy]$ ]]; then
				sudo apt-get update && sudo apt-get install -y xorg-xcursorgen librsvg2-bin python3 git
			else
				echo "Build aborted: missing dependencies."
				exit 1
			fi
		else
			echo "Please install missing dependencies and rerun this script."
			exit 1
		fi
	fi
}

function create {
	local current_dir="$PWD"
	cd "$SRC"
	mkdir -p x1 x1_25 x1_5 x2
	cd "$SRC"/$1
	find . -name "*.svg" -exec sh -c 'rsvg-convert -w 32 -h 32 "$0" -o "../x1/$(basename "$0" .svg).png"' {} \;
	find . -name "*.svg" -exec sh -c 'rsvg-convert -w 40 -h 40 "$0" -o "../x1_25/$(basename "$0" .svg).png"' {} \;
	find . -name "*.svg" -exec sh -c 'rsvg-convert -w 48 -h 48 "$0" -o "../x1_5/$(basename "$0" .svg).png"' {} \;
	find . -name "*.svg" -exec sh -c 'rsvg-convert -w 64 -h 64 "$0" -o "../x2/$(basename "$0" .svg).png"' {} \;

	cd "$SRC"

	# generate cursors
	OUTPUT="$BUILD"/cursors
	ALIASES="$SRC"/cursorList

	if [ ! -d "$BUILD" ]; then
		mkdir -p "$BUILD"
	fi
	if [ ! -d "$OUTPUT" ]; then
		mkdir -p "$OUTPUT"
	fi

	echo -ne "Generating cursor theme...\\r"
	for CUR in config/*.cursor; do
		BASENAME="$CUR"
		BASENAME="${BASENAME##*/}"
		BASENAME="${BASENAME%.*}"
		
		xcursorgen "$CUR" "$OUTPUT/$BASENAME"
	done
	echo -e "Generating cursor theme... DONE"

	cd "$OUTPUT"

	# generate aliases
	echo -ne "Generating shortcuts...\\r"
	while read -r ALIAS; do
		[ -z "$ALIAS" ] && continue
		FROM="${ALIAS#* }"
		TO="${ALIAS% *}"

		if [ -e "$TO" ]; then
			continue
		fi
		ln -sr "$FROM" "$TO"
	done < "$ALIASES"
	echo -e "Generating shortcuts... DONE"

	echo -ne "Generating Theme Index...\\r"
	INDEX="$BUILD/index.theme"
	if [ ! -e "$INDEX" ]; then
		touch "$INDEX"
		echo -e "[Icon Theme]\nName=$THEME\n" > "$INDEX"
	fi
	echo -e "Generating Theme Index... DONE"

	cd "$current_dir"
}

function svg-cursors {
	local current_dir="$PWD"
	cd "$ROOT"
	rm -rf ./svg-cursor/
	rm -rf ./dist/cursors_scalable/

	if ! has_command git; then
		echo "Warning: git is required to build scalable SVG cursors."
		cd "$current_dir"
		return 0
	fi

	echo -e "Cloning svg-cursor generator tool..."
	git clone --depth 1 https://github.com/jinliu/svg-cursor.git ./svg-cursor

	echo -ne "Generating SVG cursors...\\r"
	python3 ./svg-cursor/build-svg-theme/build-svg-theme.py \
		--output-dir="$ROOT/dist/cursors_scalable" \
		--svg-dir="$SRC/svg" \
		--config-dir="$SRC/config" \
		--alias-file="$SRC/cursorList" \
		--nominal-size=24 >/dev/null 2>&1
	echo -e "Generating SVG cursors... DONE"

	# Clean up temporary build repo
	rm -rf ./svg-cursor/
	cd "$current_dir"
}

# Main execution
check_dependencies
create svg
svg-cursors

echo "Cursor build completed successfully. Output located in: $BUILD"

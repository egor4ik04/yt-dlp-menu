#!/usr/bin/env bash

set -e

# Always work from the repository directory
cd "$(dirname "$(readlink -f "$0")")"

ROOT="$PWD"
TOOLS="$ROOT/tools"
DENO_INSTALL="$TOOLS/deno"
FFMPEG_DIR="$TOOLS/ffmpeg"

export DENO_INSTALL
export PATH="$TOOLS:$DENO_INSTALL/bin:$FFMPEG_DIR/bin:$PATH"

echo "========================================"
echo "       YT Downloader - Linux Setup"
echo "========================================"
echo

# ---- Architecture -----------------------------------------------------------

case "$(uname -m)" in
    x86_64|amd64)
        YTDLP_FILE="yt-dlp_linux"
        DENO_FILE="deno-x86_64-unknown-linux-gnu.zip"
        FFMPEG_FILE="ffmpeg-master-latest-linux64-gpl.tar.xz"
        ;;
    aarch64|arm64)
        YTDLP_FILE="yt-dlp_linux_aarch64"
        DENO_FILE="deno-aarch64-unknown-linux-gnu.zip"
        FFMPEG_FILE="ffmpeg-master-latest-linuxarm64-gpl.tar.xz"
        ;;
    *)
        echo "ERROR: Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

# ---- Basic tools needed by this script (not by the project itself) ---------

MISSING=()
for cmd in curl unzip tar xz; do
    command -v "$cmd" >/dev/null 2>&1 || MISSING+=("$cmd")
done

if [ "${#MISSING[@]}" -gt 0 ]; then
    echo "Missing required tools: ${MISSING[*]}"
    echo "Attempting to install them using the system package manager..."
    echo

    PKGS=()
    for cmd in "${MISSING[@]}"; do
        if [ "$cmd" = "xz" ] && command -v apt-get >/dev/null 2>&1; then
            PKGS+=("xz-utils")
        else
            PKGS+=("$cmd")
        fi
    done

    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed "${PKGS[@]}"
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y "${PKGS[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "${PKGS[@]}"
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y "${PKGS[@]}"
    else
        echo "ERROR: Unsupported package manager."
        echo "Please install these manually and run setup.sh again: ${MISSING[*]}"
        exit 1
    fi
    echo
fi

# Download to a temp file first, so a failed download never breaks
# an already working tool (and a running binary can be replaced safely).
download() {
    curl -fL --retry 3 "$1" -o "$2.tmp"
    mv -f "$2.tmp" "$2"
}

mkdir -p "$TOOLS" "$DENO_INSTALL/bin"

# ---- 1. yt-dlp --------------------------------------------------------------

echo "[1/3] Updating yt-dlp nightly..."

download "https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/$YTDLP_FILE" "$TOOLS/yt-dlp"
chmod +x "$TOOLS/yt-dlp"

# ---- 2. Deno ----------------------------------------------------------------

echo
echo "[2/3] Installing or updating Deno..."

# Deno is downloaded as a plain zip into tools/deno/bin.
# The official install.sh is NOT used, because it may edit shell profiles.
download "https://github.com/denoland/deno/releases/latest/download/$DENO_FILE" "$TOOLS/deno.zip"
unzip -oq "$TOOLS/deno.zip" -d "$DENO_INSTALL/bin"
rm -f "$TOOLS/deno.zip"
chmod +x "$DENO_INSTALL/bin/deno"

# ---- 3. FFmpeg --------------------------------------------------------------

echo
echo "[3/3] Checking FFmpeg..."

if [ -x "$FFMPEG_DIR/bin/ffmpeg" ] && [ -x "$FFMPEG_DIR/bin/ffprobe" ]; then
    echo "FFmpeg is already installed locally, skipping."
    echo "To update it, delete the tools/ffmpeg folder and run setup.sh again."
else
    echo "FFmpeg not found in tools/ffmpeg, downloading (this may take a while)..."

    FFMPEG_TMP="$TOOLS/ffmpeg_tmp"
    rm -rf "$FFMPEG_TMP"
    mkdir -p "$FFMPEG_TMP"

    download "https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/$FFMPEG_FILE" "$TOOLS/ffmpeg.tar.xz"
    tar -xJf "$TOOLS/ffmpeg.tar.xz" -C "$FFMPEG_TMP" --strip-components=1

    mkdir -p "$FFMPEG_DIR/bin"
    cp -f "$FFMPEG_TMP/bin/ffmpeg" "$FFMPEG_TMP/bin/ffprobe" "$FFMPEG_DIR/bin/"
    chmod +x "$FFMPEG_DIR/bin/ffmpeg" "$FFMPEG_DIR/bin/ffprobe"

    rm -rf "$FFMPEG_TMP" "$TOOLS/ffmpeg.tar.xz"
fi

# ---- Checks -----------------------------------------------------------------

echo
echo "Checking yt-dlp..."
"$TOOLS/yt-dlp" --version

echo
echo "Checking Deno..."
"$DENO_INSTALL/bin/deno" --version

echo
echo "Checking FFmpeg..."
"$FFMPEG_DIR/bin/ffmpeg" -version | head -n 1

echo
echo "========================================"
echo "Setup completed!"
echo
echo "You can now launch ./yt_menu.sh"
echo "========================================"
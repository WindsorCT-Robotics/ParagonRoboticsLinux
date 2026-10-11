#!/bin/bash
# Post-build script: create home symlinks for the WPILib version tree in /usr/local.
# Runs after the 'files' module copies files/system/* into the image root.
# The WPILib tree must already exist at /usr/local/share/wpilib/<WPILIB_YEAR>/;
# this script creates a real directory under /etc/skel with subtree symlinks so
# per-student home copies map correctly onto the read-only /usr/local tree.
set -euo pipefail

# Read WPILib configuration from build-configuration.json
CONFIG_FILE="$(dirname "$0")/../build-configuration.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "wpilib-bootstrap: ERROR — build-configuration.json not found at ${CONFIG_FILE}"; exit 1
fi

WPILIB_VERSION=$(jq -r '.wpilib.version' "$CONFIG_FILE")
WPILIB_YEAR=$(jq -r '.wpilib.year' "$CONFIG_FILE")

WPILIB_ROOT="/usr/local/share/wpilib/${WPILIB_YEAR}"
SKEL_WPILIB="/etc/skel/.local/share/wpilib/${WPILIB_YEAR}"

if [ ! -d "$WPILIB_ROOT" ]; then
  echo "wpilib-bootstrap: ERROR — WPILib root tree not found at ${WPILIB_ROOT}"; exit 1
fi

mkdir -p "$(dirname "$SKEL_WPILIB")"

# VS Code user-data dir (created at image build, writable by students)
SKEL_CODE="/etc/skel/.local/state/wpilib/${WPILIB_YEAR}/code"
mkdir -p "$SKEL_CODE/User"
cat > "$SKEL_CODE/User/settings.json" << 'SETTINGS'
{
    "extensions.autoCheckForUpdatedExtensions": false
}
SETTINGS

# Each link is a real directory containing subtree symlinks → /usr/local tree.
# Real dir (not single top-level symlink) so ~/logs/ extension writes work.
for dir in advantagescope elastic icons maven jdk tools vendordeps documentation vscode systemcore; do
  ln -sfn "${WPILIB_ROOT}/${dir}" "${SKEL_WPILIB}/${dir}"
done

# Set chrome-sandbox to 4755 (setuid) so Chromium's SUID sandbox works
# when unprivileged user namespaces are restricted (Aurora DX default).
chmod 4755 "${WPILIB_ROOT}/vscode/VSCode-linux-x64/chrome-sandbox"

# Create a symlink in /etc/skel so students can install extensions to their
# year-gated home directory while still having access to pre-installed extensions.
# VS Code uses --extensions-dir to point to ~/.../code/extensions, so this
# symlink makes the pre-installed extensions accessible without write access
# to /usr/local.
mkdir -p "$SKEL_CODE"
ln -sfn "${WPILIB_ROOT}/vscode/VSCode-linux-x64/data/extensions/*" "${SKEL_CODE}/extensions"

# --- Seed Gradle dist zip (real file, not symlink — wrapper extracts into home) ---
# Find the gradle zip in installUtils and derive the dist dir name from it.
GRADLE_ZIP=$(find "${WPILIB_ROOT}/installUtils" -name 'gradle-*-bin.zip' 2>/dev/null | head -1)
if [ -z "$GRADLE_ZIP" ]; then
  echo "wpilib-bootstrap: ERROR — no gradle zip found in ${WPILIB_ROOT}/installUtils"; exit 1
fi
DIST_DIR=$(basename "$GRADLE_ZIP" .zip)

# Read distribution URL from gradle-wrapper.properties (glob the extension dir).
GRADLE_WRAPPER_PROPS="${WPILIB_ROOT}/vscode/VSCode-linux-x64/data/extensions/wpilibsuite.vscode-wpilib-*/resources/gradle/shared/gradle/wrapper/gradle-wrapper.properties"
if [ -f "$GRADLE_WRAPPER_PROPS" ]; then
  DIST_URL=$(grep '^distributionUrl=' "$GRADLE_WRAPPER_PROPS" | sed 's/distributionUrl=//' | sed 's/\\//g' | sed 's/"//g')
  HASH_DIR=$(python3 -c "
import hashlib, sys
n = int.from_bytes(hashlib.md5(sys.argv[1].encode()).digest(), 'big')
d = '0123456789abcdefghijklmnopqrstuvwxyz'
s = ''
while n: s = d[n % 36] + s; n //= 36
print(s or '0')
" "$DIST_URL")
else
  echo "wpilib-bootstrap: WARNING — gradle-wrapper.properties not found, using hardcoded hash"
  HASH_DIR="arn2x92ynaizyzdaamcbpbhtj"
fi

mkdir -p "${SKEL_WPILIB}/.gradle/wrapper/dists/${DIST_DIR}/${HASH_DIR}"
mkdir -p "${SKEL_WPILIB}/.gradle/permwrapper/dists/${DIST_DIR}/${HASH_DIR}"
cp "$GRADLE_ZIP" "${SKEL_WPILIB}/.gradle/wrapper/dists/${DIST_DIR}/${HASH_DIR}/"
cp "$GRADLE_ZIP" "${SKEL_WPILIB}/.gradle/permwrapper/dists/${DIST_DIR}/${HASH_DIR}/"
echo "wpilib-bootstrap: Gradle hash=${HASH_DIR} dist=${DIST_DIR}"

count=$(ls -d "${SKEL_WPILIB}"/*/ 2>/dev/null | wc -l)
echo "wpilib-bootstrap: created ${count} home symlinks under ${SKEL_WPILIB}"

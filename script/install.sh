#!/usr/bin/env bash
set -euo pipefail

APP_NAME="LookAway"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_APP="$PROJECT_DIR/dist/$APP_NAME.app"
USER_APPLICATIONS_DIR="${LOOKAWAY_INSTALL_DIR:-${HOME}/Applications}"
INSTALLED_APP="$USER_APPLICATIONS_DIR/$APP_NAME.app"

if ! command -v swift >/dev/null 2>&1; then
  echo "Swift is required. Run 'xcode-select --install' first, then try again." >&2
  exit 1
fi

LOOKAWAY_BUILD_CONFIGURATION=release "$SCRIPT_DIR/build_and_run.sh" --build

mkdir -p "$USER_APPLICATIONS_DIR"
/usr/bin/ditto "$SOURCE_APP" "$INSTALLED_APP"
/usr/bin/open "$INSTALLED_APP"

echo "Installed and opened $INSTALLED_APP"

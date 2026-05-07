#!/usr/bin/env bash
# =============================================================================
# Heethr Mobile — tmux-integrated Launcher
#
# Adds a "Mobile" window to an existing Heethr tmux session, running:
#   - Flutter pub get (if deps not satisfied)
#   - flutter run -d chrome
#
# IMPORTANT: This script patches lib/core/constant/constant.dart to point to
# the local backend (http://localhost:3000). It restores the production URL
# on exit. DO NOT use this for production work.
#
# Requirements:
#   - Must be run INSIDE the Heethr tmux session (via tmux send-keys)
#   - The Heethr backend system must already be running at :3000
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[heethr-mobile]${NC} $1"; }
warn() { echo -e "${YELLOW}[heethr-mobile]${NC} $1"; }
die()  { echo -e "${RED}[heethr-mobile]${NC} $1" >&2; exit 1; }

REPO_ROOT="/home/lucas/Work/Heethr"
MOBILE_DIR="$REPO_ROOT/snow-melting_mobile"
CONSTANT_FILE="$MOBILE_DIR/lib/core/constant/constant.dart"
CONSTANT_BACKUP="$CONSTANT_FILE.bak.heethr-mobile"

LOCAL_API="http://localhost:3000"

# -----------------------------------------------------------------------------
# Cleanup handler — restore production URL no matter how we exit
# -----------------------------------------------------------------------------
restore_constant() {
  if [ -f "$CONSTANT_BACKUP" ]; then
    log "Restoring production API URL..."
    cp "$CONSTANT_BACKUP" "$CONSTANT_FILE"
    rm -f "$CONSTANT_BACKUP"
    log "Production URL restored."
  fi
}
trap restore_constant EXIT INT TERM

# -----------------------------------------------------------------------------
# Verify backend is running (pre-requisite for this script)
# -----------------------------------------------------------------------------
if ! curl -s "http://localhost:3000/swagger" > /dev/null 2>&1; then
  die "Heethr backend is not running at http://localhost:3000."
  die "Start the Heethr system first using: start"
fi

# -----------------------------------------------------------------------------
# Verify we are in the right place
# -----------------------------------------------------------------------------
if [ ! -f "$CONSTANT_FILE" ]; then
  die "constant.dart not found at $CONSTANT_FILE."
fi

if [ ! -d "$MOBILE_DIR" ]; then
  die "Mobile directory not found at $MOBILE_DIR."
fi

# -----------------------------------------------------------------------------
# Guard: stale backup means another session may be running
# -----------------------------------------------------------------------------
if [ -f "$CONSTANT_BACKUP" ]; then
  die "Stale backup found ($CONSTANT_BACKUP). Another mobile session may be running."
  die "Run './stop-local-mobile.sh' first or kill the stale session."
fi

# -----------------------------------------------------------------------------
# Check google_fonts compatibility
# -----------------------------------------------------------------------------
log "Checking google_fonts version..."
CURRENT_GF=$(grep "google_fonts:" "$MOBILE_DIR/pubspec.yaml" | sed 's/.*google_fonts:.*\^//' | tr -d ' ')
if [ "$(printf '%s\n' "6.3.1" "$CURRENT_GF" | sort -V | head -n1)" = "6.3.1" ] && [ "$CURRENT_GF" = "6.3.1" ]; then
  warn "google_fonts 6.3.1 has a Dart SDK compatibility bug. Upgrading..."
  cd "$MOBILE_DIR"
  flutter pub upgrade google_fonts
  log "google_fonts upgraded."
fi

# -----------------------------------------------------------------------------
# Patch constant.dart to use local API
# -----------------------------------------------------------------------------
log "Backing up and patching constant.dart for local development..."
cp "$CONSTANT_FILE" "$CONSTANT_BACKUP"

sed -i "s|static const String protocol = 'https';|static const String protocol = 'http';|g" "$CONSTANT_FILE"
sed -i "s|static const String ipPort = 'api.heethr.com';|static const String ipPort = 'localhost:3000';|g" "$CONSTANT_FILE"

log "Patched constant.dart:"
grep -E "protocol|ipPort|baseUrl|baseImageUrl" "$CONSTANT_FILE" | sed 's/^/  /'

# -----------------------------------------------------------------------------
# Run flutter pub get and launch in Chrome
# -----------------------------------------------------------------------------
log "Running flutter pub get..."
cd "$MOBILE_DIR"
flutter pub get

echo ""
log "=========================================="
log "LAUNCHING MOBILE IN CHROME — LOCAL MODE"
log "=========================================="
log ""
log "  Backend:  http://localhost:3000"
log "  Swagger:  http://localhost:3000/swagger"
log "  App:      Chrome (web target)"
log ""
log "Local test accounts:"
log "  contractor@heethr.test / Test1234!"
log "  admin@heethr.test     / Test1234!"
log ""
warn "Production URL will be RESTORED when this session/window closes."
log ""
log "Starting Flutter in Chrome..."
echo ""

flutter run -d chrome

# trap restores constant.dart on exit
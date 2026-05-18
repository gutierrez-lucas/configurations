#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: agentdeck-opencode.sh <title> [--parent <session>] [--group <group>] [--path <dir>] [--message <prompt>]

Examples:
  adoc "Heethr API"
  adoc "Heethr Shop" --parent "Heethr Commander"
  adoc "Heethr Mobile" --group heethr --path /home/lucas/Work/Heethr/snow-melting_mobile
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v agent-deck >/dev/null 2>&1; then
  printf 'agent-deck not found on PATH\n' >&2
  exit 1
fi

if ! command -v opencode >/dev/null 2>&1; then
  printf 'opencode not found on PATH\n' >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'jq not found on PATH\n' >&2
  exit 1
fi

TITLE="${1:-}"
if [[ -z "$TITLE" ]]; then
  printf 'session title required\n\n' >&2
  usage >&2
  exit 1
fi
shift || true

PARENT=""
GROUP=""
WORKDIR="$PWD"
MESSAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --parent)
      PARENT="${2:?missing value for --parent}"
      shift 2
      ;;
    --group)
      GROUP="${2:?missing value for --group}"
      shift 2
      ;;
    --path)
      WORKDIR="${2:?missing value for --path}"
      shift 2
      ;;
    --message|-m)
      MESSAGE="${2:?missing value for --message}"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "$WORKDIR" ]]; then
  printf 'path does not exist: %s\n' "$WORKDIR" >&2
  exit 1
fi

if [[ -z "$PARENT" ]]; then
  PARENT=$(agent-deck session current -q 2>/dev/null || true)
fi

if [[ -z "$PARENT" ]]; then
  printf 'no current agent-deck parent found; run from inside an agent-deck session or pass --parent\n' >&2
  exit 1
fi

if [[ -z "$GROUP" ]]; then
  GROUP=$(agent-deck session show "$PARENT" --json 2>/dev/null | jq -r '.group // empty' || true)
fi

add_args=("$WORKDIR" -t "$TITLE" -c opencode --parent "$PARENT")
if [[ -n "$GROUP" ]]; then
  add_args+=( -g "$GROUP" )
fi

agent-deck add "${add_args[@]}"

if [[ -n "$MESSAGE" ]]; then
  agent-deck session start -m "$MESSAGE" "$TITLE"
else
  agent-deck session start "$TITLE"
fi

printf 'started child session: %s\n' "$TITLE"

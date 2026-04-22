#!/usr/bin/env zsh
# launcher-popup.sh — compact top-level menu.
# Accepts a result file as $1; writes the selection to it so the wrapper
# can act on it after this popup closes.

SCRIPTS_DIR="$HOME/.scripts"
RESULT_FILE="$1"

# Clear global fzf defaults — they include --multi, --preview, etc. which
# interfere with this compact menu. Also prevents residual mouse events
# (from the status-bar click that opened this popup) from auto-selecting.
FZF_DEFAULT_OPTS=''
FZF_DEFAULT_OPTS_FILE=''

FZF_THEME="fg:#cdd6f4,fg+:#cdd6f4,bg:#1e1e2e,bg+:#313244,\
hl:#89b4fa,hl+:#89b4fa,info:#cba6f7,prompt:#cba6f7,\
pointer:#f38ba8,marker:#a6e3a1,header:#89dceb,\
border:#45475a,label:#cdd6f4,\
preview-fg:#cdd6f4,preview-bg:#181825"

VIM_BINDS='j:down,k:up,ctrl-d:half-page-down,ctrl-u:half-page-up,g:first,G:last'

menu=(
  $'\e[38;5;228m󰃬\e[0m  Calculator    bc — interactive calculator'
  $'\e[38;5;114m󰏗\e[0m  Projects      Launch or manage a project'
  $'\e[38;5;82m$\e[0m  Dólar         Cotizaciones del dólar'
)

selected=$(printf '%s\n' "${menu[@]}" | fzf \
  --ansi \
  --no-sort \
  --border=rounded \
  --border-label='   Launcher  ' \
  --border-label-pos=2 \
  --color="$FZF_THEME" \
  --prompt='  › ' \
  --pointer='▶' \
  --height=100% \
  --header=$'\n  esc to close\n' \
  --header-first \
  --no-info \
  --no-mouse \
  --bind="$VIM_BINDS" \
)

[[ -z "$selected" ]] && exit 0

case "$selected" in
  *Calculator*)
    printf 'calc' > "$RESULT_FILE"
    exit 0
    ;;
  *Projects*)
    printf 'projects' > "$RESULT_FILE"
    exit 0
    ;;
  *Dólar*)
    printf 'dolar' > "$RESULT_FILE"
    exit 0
    ;;
esac

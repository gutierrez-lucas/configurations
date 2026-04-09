#!/usr/bin/env zsh

SELF="${(%):-%x}"
SCRIPTS_DIR="/home/lucas/.scripts"

# ── Project registry ───────────────────────────────────────────────────────────
# NAME | SESSION | DIR | LAUNCH | CLOSE | DESC
typeset -a PROJECTS=(
  "Heethr|Heethr|/home/lucas/Work/Heethr|$SCRIPTS_DIR/launch_heethr.sh|$SCRIPTS_DIR/close_heethr.sh|Snow melting platform — backend, dashboard & shop"
  "FlareSense|FlareSense|/home/lucas/Work/FlareSense|$SCRIPTS_DIR/launch_flare.sh|$SCRIPTS_DIR/close_flare.sh|ESP32 firmware & environmental sensing"
)

# ── Vim motion binds ──────────────────────────────────────────────────────────
VIM_BINDS='j:down,k:up,ctrl-d:half-page-down,ctrl-u:half-page-up,g:first,G:last'

# ── Catppuccin Mocha ───────────────────────────────────────────────────────────
FZF_THEME="fg:#cdd6f4,fg+:#cdd6f4,bg:#1e1e2e,bg+:#313244,\
hl:#89b4fa,hl+:#89b4fa,info:#cba6f7,prompt:#cba6f7,\
pointer:#f38ba8,marker:#a6e3a1,header:#89dceb,\
border:#45475a,label:#cdd6f4,\
preview-fg:#cdd6f4,preview-bg:#181825"

# ── Self-invoked preview mode ─────────────────────────────────────────────────
if [[ "$1" == "--preview" ]]; then
  IFS='|' read -r name session dir launch close desc <<< "$2"

  printf '\n'
  printf '  \033[1m\033[38;5;117m%s\033[0m\n' "$name"
  printf '  \033[2m%s\033[0m\n' "$desc"
  printf '\n'
  printf '  \033[38;5;183m dir  \033[0m\033[2m%s\033[0m\n' "$dir"
  printf '\n'

  # Session status
  if tmux has-session -t "$session" 2>/dev/null; then
    printf '  \033[38;5;114m● session active\033[0m\n'
    printf '\n'
    printf '  \033[2mwindows\033[0m\n'
    tmux list-windows -t "$session" -F "    #I  #W" 2>/dev/null | \
      while IFS= read -r line; do
        printf '  \033[38;5;117m%s\033[0m\n' "$line"
      done
  else
    printf '  \033[38;5;210m○ session not running\033[0m\n'
  fi

  printf '\n'

  # Git info
  if [[ -d "$dir/.git" ]]; then
    branch=$(git -C "$dir" branch --show-current 2>/dev/null)
    last=$(git -C "$dir" log -1 --format="%h  %s" 2>/dev/null)
    dirty=$(git -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

    printf '  \033[38;5;159m git\033[0m\n'
    printf '\n'
    printf '  \033[2mbranch\033[0m      \033[38;5;228m%s\033[0m\n' "$branch"
    printf '  \033[2mlast\033[0m        \033[2m%s\033[0m\n' "$last"
    if [[ "$dirty" -gt 0 ]]; then
      printf '  \033[2mstatus\033[0m      \033[38;5;210m%d uncommitted change(s)\033[0m\n' "$dirty"
    else
      printf '  \033[2mstatus\033[0m      \033[38;5;114mclean\033[0m\n'
    fi
  fi

  printf '\n'
  exit 0
fi

# ── Build fzf entries ─────────────────────────────────────────────────────────
typeset -a entries=()
for proj in "${PROJECTS[@]}"; do
  IFS='|' read -r name session dir launch close desc <<< "$proj"
  if tmux has-session -t "$session" 2>/dev/null; then
    dot=$'\e[38;5;114m●\e[0m'
  else
    dot=$'\e[38;5;210m○\e[0m'
  fi
  name_col=$(printf '%-14s' "$name")
  desc_dim=$'\e[2m'"$desc"$'\e[0m'
  entries+=("${dot}  ${name_col}  ${desc_dim}"$'\t'"${proj}")
done

# ── Project picker ────────────────────────────────────────────────────────────
selected=$(printf '%s\n' "${entries[@]}" | fzf \
  --ansi \
  --no-sort \
  --delimiter=$'\t' \
  --with-nth=1 \
  --border=rounded \
  --border-label='  Project Launcher  ' \
  --border-label-pos=2 \
  --color="$FZF_THEME" \
  --preview="'$SELF' --preview '{2}'" \
  --preview-window='right:48%:wrap:border-left' \
  --prompt='  › ' \
  --pointer='▶' \
  --marker='✓' \
  --height=70% \
  --header=$'\n  esc to quit\n' \
  --header-first \
  --no-info \
  --bind="$VIM_BINDS" \
)

[[ -z "$selected" ]] && exit 0

proj_data=$(printf '%s' "$selected" | cut -f2)
IFS='|' read -r name session dir launch close desc <<< "$proj_data"

# ── Action picker ─────────────────────────────────────────────────────────────
typeset -a actions=()
if tmux has-session -t "$session" 2>/dev/null; then
  actions+=(
    $'\e[38;5;117m▶\e[0m  attach    Connect to running session'
    $'\e[38;5;228m↺\e[0m  restart   Close and relaunch'
    $'\e[38;5;210m■\e[0m  close     Kill the session and stop services'
  )
else
  actions+=(
    $'\e[38;5;114m▶\e[0m  launch    Start a new session'
  )
fi

action_line=$(printf '%s\n' "${actions[@]}" | fzf \
  --ansi \
  --no-sort \
  --border=rounded \
  --border-label="  $name  " \
  --border-label-pos=2 \
  --color="$FZF_THEME" \
  --prompt='  › ' \
  --pointer='▶' \
  --height=40% \
  --header=$'\n  Choose an action\n' \
  --header-first \
  --no-info \
  --bind="$VIM_BINDS" \
)

[[ -z "$action_line" ]] && exit 0

action=$(printf '%s' "$action_line" | awk '{print $2}')

GREEN=$'\033[38;5;114m'
NC=$'\033[0m'

case "$action" in
  launch)
    printf "\n${GREEN}  Launching ${name}...${NC}\n\n"
    zsh "$launch" --here
    ;;
  attach)
    printf "\n${GREEN}  Attaching to ${name}...${NC}\n\n"
    tmux attach-session -t "$session"
    ;;
  close)
    printf "\n${GREEN}  Closing ${name}...${NC}\n\n"
    zsh "$close"
    ;;
  restart)
    printf "\n${GREEN}  Restarting ${name}...${NC}\n\n"
    zsh "$close" && sleep 1 && zsh "$launch" --here
    ;;
esac

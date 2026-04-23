#!/usr/bin/env zsh

SELF="${(%):-%x}"
SCRIPTS_DIR="/home/lucas/.scripts"
PROJECTS_DIR="$SCRIPTS_DIR/projects"

# Clear global fzf defaults — prevents --multi, --preview=cat, and other
# ambient options from interfering. Also blocks residual mouse events from
# the click that opened this popup from auto-selecting entries.
FZF_DEFAULT_OPTS=''
FZF_DEFAULT_OPTS_FILE=''

# ── Project registry ───────────────────────────────────────────────────────────
# Each entry is the path to a project.json file.
typeset -a PROJECT_FILES=(
  "$PROJECTS_DIR/heethr.json"
  "$PROJECTS_DIR/flaresense.json"
  "$PROJECTS_DIR/notes.json"
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
  JSON="$2"
  [[ ! -f "$JSON" ]] && exit 0

  name=$(jq    -r '.name'             "$JSON")
  desc=$(jq    -r '.description'      "$JSON")
  dir=$(jq     -r '.dir'              "$JSON")
  session=$(jq -r '.session // empty' "$JSON")

  printf '\n'
  printf '  \033[1m\033[38;5;117m%s\033[0m\n' "$name"
  printf '  \033[2m%s\033[0m\n' "$desc"
  printf '\n'
  printf '  \033[38;5;183m dir  \033[0m\033[2m%s\033[0m\n' "$dir"
  printf '\n'

  # Session status
  if [[ -n "$session" ]]; then
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
  else
    printf '  \033[38;5;245m— no session\033[0m\n'
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
for json in "${PROJECT_FILES[@]}"; do
  [[ ! -f "$json" ]] && continue

  name=$(jq    -r '.name'             "$json")
  desc=$(jq    -r '.description'      "$json")
  session=$(jq -r '.session // empty' "$json")
  icon=$(jq    -r '.icon // ""'       "$json")

  if [[ -n "$session" ]] && tmux has-session -t "$session" 2>/dev/null; then
    dot=$'\e[38;5;114m●\e[0m'
  else
    dot=$'\e[38;5;210m○\e[0m'
  fi

  icon_col=$(printf '%-2s' "$icon")
  name_col=$(printf '%-14s' "$name")
  desc_dim=$'\e[2m'"$desc"$'\e[0m'
  entries+=("${dot}  ${icon_col}  ${name_col}  ${desc_dim}"$'\t'"${json}")
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
  --preview="zsh $SELF --preview {2}" \
  --preview-window='right:48%:wrap:border-left' \
  --prompt='  › ' \
  --pointer='▶' \
  --marker='✓' \
  --height=100% \
  --header=$'\n  esc to quit\n' \
  --header-first \
  --no-info \
  --no-mouse \
  --bind="$VIM_BINDS" \
  --bind='start:unbind(enter)' \
  --bind='load:rebind(enter)' \
)

[[ -z "$selected" ]] && exit 0

IFS=$'\t' read -r _display json <<< "$selected"
name=$(jq    -r '.name'             "$json")
session=$(jq -r '.session // empty' "$json")
dir=$(jq     -r '.dir'              "$json")

# ── Read all lifecycle keys dynamically ───────────────────────────────────────
# lc_keys: ordered list of key names present in lifecycle
# lc_map:  associative array  key -> script path
typeset -a lc_keys=()
typeset -A lc_map=()
if jq -e '.lifecycle' "$json" &>/dev/null; then
  while IFS=$'\t' read -r key script_path; do
    lc_keys+=("$key")
    lc_map[$key]="$script_path"
  done < <(jq -r '.lifecycle | to_entries[] | [.key, .value] | @tsv' "$json")
fi

# ── Action icon lookup ────────────────────────────────────────────────────────
typeset -A ACTION_ICONS=(
  [start]="▶"
  [stop]="■"
  [restart]="↺"
  [build]="󰑮"
  [deploy]="󰅧"
  [logs]="󰌱"
  [sync]="󰓦"
  [open]="󰏌"
  [test]=""
)

# ── Action picker ─────────────────────────────────────────────────────────────
# Only lifecycle-defined actions are shown.
# Entries are tab-delimited:  <display>\t<action_tag>\t<script_path>
typeset -a actions=()

for key in "${lc_keys[@]}"; do
  action_icon="${ACTION_ICONS[$key]:-⚙}"
  actions+=(
    $'\e[38;5;228m'"${action_icon}"$'\e[0m  '"$key"$'\t'"lc:$key"$'\t'"${lc_map[$key]}"
  )
done

[[ ${#actions[@]} -eq 0 ]] && exit 0

selected_action=$(printf '%s\n' "${actions[@]}" | fzf \
  --ansi \
  --no-sort \
  --delimiter=$'\t' \
  --with-nth=1 \
  --border=rounded \
  --border-label="  $name  " \
  --border-label-pos=2 \
  --color="$FZF_THEME" \
  --prompt='  › ' \
  --pointer='▶' \
  --height=100% \
  --header=$'\n  Choose an action\n' \
  --header-first \
  --no-info \
  --no-mouse \
  --bind="$VIM_BINDS" \
  --bind='start:unbind(enter)' \
  --bind='load:rebind(enter)' \
)

[[ -z "$selected_action" ]] && exit 0

IFS=$'\t' read -r _display action_tag action_script <<< "$selected_action"

GREEN=$'\033[38;5;114m'
NC=$'\033[0m'

lc_key="${action_tag#lc:}"
printf "\n${GREEN}  Running ${name} ${lc_key}...${NC}\n\n"

# Expand ~ and run the command with zsh to preserve all syntax
LAUNCHED_FROM_PROJECTS=1 zsh -c "$(echo "$action_script" | sed "s|~|$HOME|g")"

# After a start action, switch focus to the new session.
# If a tmux client exists, switch it there.
# Otherwise open a new Alacritty window, fully detached so it survives
# after the launcher terminal closes.
if [[ "$lc_key" == "start" && -n "$session" ]]; then
  if tmux list-clients 2>/dev/null | grep -q .; then
    tmux switch-client -t "$session" 2>/dev/null
  else
    setsid alacritty -e tmux attach-session -t "$session" >/dev/null 2>&1 &
  fi
fi

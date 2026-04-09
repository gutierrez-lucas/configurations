# TODO on terminal open
glow ~/Documents/notes/VaultTec/_TODO.md

bindkey '^ ' autosuggest-accept

# Enable Powerlevel10k instant prompt (keep near the top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.local/bin:$PATH"
export FZF_PATH="$HOME/.fzf"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins (oh-my-zsh will load these automatically if installed under $ZSH_CUSTOM/plugins)
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  fzf-zsh-plugin
)

source $ZSH/oh-my-zsh.sh

# Rust environment (only source if file exists)
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Brew environment (only if installed)
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# User configuration
unsetopt autocd

# Plugin safety checks (manual sourcing if not using oh-my-zsh plugin system)
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [ -f ~/.zsh/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh ]; then
#  source ~/.zsh/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh
fi

# ESP-IDF aliases
alias exportidf='. /home/lucas/esp/esp-idf/export.sh'
alias flashmonitor='idf.py flash -p /dev/ttyACM0 monitor -p /dev/ttyACM0'
alias monitor='idf.py monitor -p /dev/ttyACM0'
alias eraseflash='idf.py erase_flash -p /dev/ttyACM0'
alias menuconfig='idf.py menuconfig'
alias build='idf.py build'

# Powerlevel10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# File system
alias ls='eza --icons --color=always'
if command -v eza &> /dev/null; then
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lsa='ls -a'
    alias lt='eza --tree --level=2 --long --icons --git'
    alias lta='lt -a'
fi

alias gist='git status'
alias gil='git log --graph --oneline --all --color'
## scripts
alias launch_flare='/home/lucas/.scripts/launch_flare.sh'
alias launch_heethr='/home/lucas/.scripts/launch_heethr.sh'

# TODO
alias todo='/home/lucas/.scripts/todo.sh'
alias ta='todo add'
alias tl='todo list'
alias te='todo edit'


eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[ -f ~/.fzf.zsh ] && FZF_PATH="$HOME/.fzf" source ~/.fzf.zsh

# fnm
FNM_PATH="/home/lucas/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

#!/usr/bin/env bash
# setup.sh — New Ubuntu device bootstrap
# Installs ALL dependencies (with version checks) and applies dotfiles from this repo.
# Fully non-interactive. Idempotent — safe to run multiple times.
#
# Dependency chain:
#   Phase 0 (bootstrap)  → must exist on a bare Ubuntu before anything else
#   Phase 1+            → all other tools, checked + installed in strict order
#   Phase N (dotfiles)  → applied LAST after every tool is verified

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

USER="${USER:-$(id -un)}"
HOME="${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
export USER HOME

# ── output helpers ───────────────────────────────────────────────────────────────
info()    { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
success() { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
warn()    { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
die()     { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

require_ubuntu() {
  if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
    die "This script targets Ubuntu. Detected: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2)"
  fi
}

# ── version helpers ────────────────────────────────────────────────────────────
# Compare semantic versions: vercmp <actual> <required> → 0 if ok, 1 if upgrade needed
vercmp() {
  local actual="$1" required="$2"
  local a_major a_minor a_patch r_major r_minor r_patch
  IFS='.' read -r a_major a_minor a_patch <<< "${actual#v}"
  IFS='.' read -r r_major r_minor r_patch <<< "${required#v}"
  a_major="${a_major:-0}"; a_minor="${a_minor:-0}"; a_patch="${a_patch:-0}"
  r_major="${r_major:-0}"; r_minor="${r_minor:-0}"; r_patch="${r_patch:-0}"
  if   [ "$a_major" -lt "$r_major" ]; then return 1
  elif [ "$a_major" -gt "$r_major" ]; then return 0
  elif [ "$a_minor" -lt "$r_minor" ]; then return 1
  elif [ "$a_minor" -gt "$r_minor" ]; then return 0
  elif [ "$a_patch" -lt "$r_patch" ]; then return 1
  fi
  return 0
}

# ── PHASE 0: Bootstrap — absolute minimum tools needed on a bare Ubuntu ───────
# These 4 tools must exist before ANY other installer can work.
# No version checks here — just bare existence.

bootstrap_base_tools() {
  info "=== Phase 0: Bootstrap (base tools) ==="

  local missing=()
  for tool in git curl wget unzip; do
    if ! command -v "$tool" &>/dev/null; then
      missing+=("$tool")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    info "All base tools present — skipping."
  else
    info "Installing: ${missing[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y "${missing[@]}"
  fi
  success "Phase 0 complete."
}

# ── PHASE 1: System packages via apt ───────────────────────────────────────────
install_apt_packages() {
  info "=== Phase 1: System packages ==="

  local to_install=()
  declare -A pkg_tool_map=(
    [git]="git"
    [curl]="curl"
    [wget]="wget"
    [unzip]="unzip"
    [zsh]="zsh"
    [tmux]="tmux"
    [alacritty]="alacritty"
    [fontconfig]="fontconfig"
    [fzf]="fzf"
    [ripgrep]="rg"
    [fd-find]="fd"
    [python3]="python3"
    [golang-go]="go"
    [lua5.4]="lua"
    [clangd]="clangd"
    [cmake]="cmake"
    [ninja-build]="ninja"
    [xclip]="xclip"
    [xdotool]="xdotool"
  )

  for pkg in "${!pkg_tool_map[@]}"; do
    tool="${pkg_tool_map[$pkg]}"
    if ! command -v "$tool" &>/dev/null && ! dpkg -s "$pkg" &>/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done

  # zsh-syntax-highlighting (apt handles this separately as it has no binary)
  if [ ! -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] \
     && ! dpkg -s zsh-syntax-highlighting &>/dev/null 2>&1; then
    to_install+=("zsh-syntax-highlighting")
  fi

  if [ ${#to_install[@]} -eq 0 ]; then
    info "All apt packages present — skipping."
  else
    info "Installing: ${to_install[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y "${to_install[@]}"
  fi
  success "Phase 1 complete."
}

# ── PHASE 2: Version-aware tool installations ──────────────────────────────────
# Each function: checks tool + version. Installs only if missing or version too low.
# All downloads use tools guaranteed by Phase 0 (git, curl, wget, unzip).

# ── 2a. zsh ≥ 5.1 (Oh My Zsh and powerlevel10k instant prompt require 5.1+) ──────
install_zsh() {
  info "=== Phase 2a: zsh ==="
  local REQUIRED="5.1"
  if command -v zsh &>/dev/null; then
    local version; version="$(zsh --version 2>&1 | grep -oP '\d+\.\d+' | head -1)"
    if vercmp "$version" "$REQUIRED"; then
      info "zsh $version (≥$REQUIRED) — skipping."
      return
    fi
    info "zsh $version found, but ≥$REQUIRED required — upgrading..."
  else
    info "zsh not found — installing..."
  fi
  sudo apt-get install -y zsh
  success "Phase 2a complete."
}

# ── 2b. tmux ≥ 2.1 (required for tmux-resurrect, tmux2k features) ──────────────
install_tmux() {
  info "=== Phase 2b: tmux ==="
  local REQUIRED="2.1"
  if command -v tmux &>/dev/null; then
    local version; version="$(tmux -V 2>&1 | grep -oP '\d+\.\d+' | head -1)"
    if vercmp "$version" "$REQUIRED"; then
      info "tmux $version (≥$REQUIRED) — skipping."
      return
    fi
    info "tmux $version found, but ≥$REQUIRED required — upgrading..."
  else
    info "tmux not found — installing..."
  fi
  sudo apt-get install -y tmux
  success "Phase 2b complete."
}

# ── 2c. Neovim ≥ 0.10 (LazyVim and most plugins require 0.10+) ─────────────────
install_neovim() {
  info "=== Phase 2c: Neovim ==="
  local REQUIRED="0.10"
  if command -v nvim &>/dev/null; then
    local version; version="$(nvim --version | head -1 | grep -oP '\d+\.\d+')"
    if vercmp "$version" "$REQUIRED"; then
      info "Neovim $version (≥$REQUIRED) — skipping."
      return
    fi
    info "Neovim $version found, but ≥$REQUIRED required — upgrading..."
  else
    info "Neovim not found — installing..."
  fi
  local TMP; TMP="$(mktemp -d)"
  wget -qO "$TMP/nvim.appimage" \
    "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
  chmod +x "$TMP/nvim.appimage"
  (cd "$TMP" && ./nvim.appimage --appimage-extract &>/dev/null)
  sudo mv "$TMP/squashfs-root" /opt/nvim
  sudo ln -sf /opt/nvim/usr/bin/nvim /usr/local/bin/nvim
  rm -rf "$TMP"
  success "Phase 2c complete."
}

# ── 2d. Node.js ≥ 18 (fnm and many LSPs require 18+) ───────────────────────────
install_nodejs() {
  info "=== Phase 2d: Node.js ==="
  local REQUIRED="18"
  if command -v node &>/dev/null; then
    local version; version="$(node --version | tr -d 'v')"
    if vercmp "$version" "$REQUIRED"; then
      info "Node.js $version (≥$REQUIRED) — skipping."
      return
    fi
    info "Node.js $version found, but ≥$REQUIRED required — upgrading..."
  else
    info "Node.js not found — installing..."
  fi
  # Use fnm to install a specific Node version (fnm itself installed in Phase 2e)
  if command -v fnm &>/dev/null; then
    fnm install 18
    fnm default 18
  else
    # Fallback: install via apt
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
    sudo apt-get install -y nodejs
  fi
  success "Phase 2d complete."
}

# ── 2e. fnm (Fast Node Manager — used in .zshrc) ───────────────────────────────
install_fnm() {
  info "=== Phase 2e: fnm ==="
  if command -v fnm &>/dev/null; then
    info "fnm already installed — skipping."
    return
  fi
  info "Installing fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash
  success "Phase 2e complete."
}

# ── 2f. Go ≥ 1.21 (gopls in nvim LSP config requires 1.21+) ──────────────────
install_golang() {
  info "=== Phase 2f: Go ==="
  local REQUIRED="1.21"
  if command -v go &>/dev/null; then
    local version; version="$(go version 2>&1 | grep -oP '\d+\.\d+')"
    if vercmp "$version" "$REQUIRED"; then
      info "Go $version (≥$REQUIRED) — skipping."
      return
    fi
    info "Go $version found, but ≥$REQUIRED required — upgrading..."
  else
    info "Go not found — installing..."
  fi
  local TMP; TMP="$(mktemp -d)"
  local VERSION="1.23.0"
  wget -qO "$TMP/go.tar.gz" \
    "https://go.dev/dl/go${VERSION}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$TMP/go.tar.gz"
  rm -rf "$TMP"
  export PATH="/usr/local/go/bin:$PATH"
  success "Phase 2f complete."
}

# ── 2g. Rust / cargo (no strict version — just ensure present) ────────────────
install_rust() {
  info "=== Phase 2g: Rust ==="
  if command -v cargo &>/dev/null; then
    info "Rust/cargo already installed — skipping."
    return
  fi
  info "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
  success "Phase 2g complete."
}

# ── 2h. Homebrew ───────────────────────────────────────────────────────────────
install_homebrew() {
  info "=== Phase 2h: Homebrew ==="
  if command -v brew &>/dev/null; then
    info "Homebrew already installed — skipping."
    return
  fi
  info "Installing Homebrew..."
  NONINTERACTIVE=1 bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # shellcheck disable=SC1091
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  success "Phase 2h complete."
}

# ── 2i. brew packages: eza, zoxide ────────────────────────────────────────────
install_brew_packages() {
  info "=== Phase 2i: brew packages (eza, zoxide) ==="
  # shellcheck disable=SC1091
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
  if command -v eza &>/dev/null && command -v zoxide &>/dev/null; then
    info "eza and zoxide present — skipping."
    return
  fi
  info "Installing eza and zoxide..."
  brew install eza zoxide
  success "Phase 2i complete."
}

# ── 2j. GitHub CLI gh (no strict version — just ensure present) ───────────────
install_gh() {
  info "=== Phase 2j: GitHub CLI ==="
  if command -v gh &>/dev/null; then
    info "gh already installed — skipping."
    return
  fi
  info "Installing gh..."
  local VERSION
  VERSION="$(curl -fsSL https://github.com/cli/cli/releases/latest \
    | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*' | head -1 | tr -d 'v')"
  local TMP; TMP="$(mktemp -d)"
  curl -fsSL "https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_amd64.tar.gz" \
    -o "$TMP/gh.tar.gz"
  tar -xzf "$TMP/gh.tar.gz" -C "$TMP/"
  mkdir -p "$HOME/.local/bin"
  cp "$TMP/gh_${VERSION}_linux_amd64/bin/gh" "$HOME/.local/bin/gh"
  chmod +x "$HOME/.local/bin/gh"
  rm -rf "$TMP"
  success "Phase 2j complete."
}

# ── 2k. opencode (AI coding tool — just ensure present) ───────────────────────
install_opencode() {
  info "=== Phase 2k: opencode ==="
  if command -v opencode &>/dev/null; then
    info "opencode already installed — skipping."
    return
  fi
  info "Installing opencode..."
  mkdir -p "$HOME/.opencode/bin"
  curl -fsSL https://opencode.ai/install.sh | sh -s -- -b "$HOME/.opencode/bin"
  chmod +x "$HOME/.opencode/bin/opencode" 2>/dev/null || true
  success "Phase 2k complete."
}

# ── 2l. jq (just ensure present — used by launch_project.sh) ─────────────────
install_jq() {
  info "=== Phase 2l: jq ==="
  if command -v jq &>/dev/null; then
    info "jq already installed — skipping."
    return
  fi
  info "Installing jq..."
  sudo apt-get install -y jq
  success "Phase 2l complete."
}

# ── PHASE 3: Nerd Fonts (JetBrainsMono — used by p10k + alacritty) ─────────────
install_nerd_fonts() {
  info "=== Phase 3: JetBrainsMono Nerd Font ==="
  if fc-list | grep -qi "JetBrainsMono"; then
    info "JetBrainsMono Nerd Font already installed — skipping."
    return
  fi
  info "Installing JetBrainsMono Nerd Font..."
  local TMP; TMP="$(mktemp -d)"
  wget -qO "$TMP/JetBrainsMono.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
  unzip -qo "$TMP/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/JetBrainsMono"
  fc-cache -f
  rm -rf "$TMP"
  success "Phase 3 complete."
}

# ── PHASE 4: Oh My Zsh ────────────────────────────────────────────────────────
install_ohmyzsh() {
  info "=== Phase 4: Oh My Zsh ==="
  if [ -d "$HOME/.oh-my-zsh" ]; then
    info "Oh My Zsh already installed — skipping."
    return
  fi
  info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  success "Phase 4 complete."
}

# ── PHASE 5: Powerlevel10k ───────────────────────────────────────────────────
install_p10k() {
  info "=== Phase 5: Powerlevel10k ==="
  local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [ -d "$P10K_DIR" ]; then
    info "Powerlevel10k already installed — skipping."
    return
  fi
  info "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  success "Phase 5 complete."
}

# ── PHASE 6: zsh plugins ────────────────────────────────────────────────────────
install_zsh_plugins() {
  info "=== Phase 6: zsh plugins ==="

  local AUTO_DIR="$HOME/.zsh/zsh-autosuggestions"
  if [ ! -d "$AUTO_DIR" ]; then
    info "Cloning zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$AUTO_DIR"
  else
    info "zsh-autosuggestions already present."
  fi

  local FZF_ZSH_DIR="$HOME/.zsh/fzf-zsh-plugin"
  if [ ! -d "$FZF_ZSH_DIR" ]; then
    info "Cloning fzf-zsh-plugin..."
    git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin.git "$FZF_ZSH_DIR"
  else
    info "fzf-zsh-plugin already present."
  fi

  if [ ! -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    warn "zsh-syntax-highlighting not found — may need apt install zsh-syntax-highlighting"
  fi

  success "Phase 6 complete."
}

# ── PHASE 7: LazyVim bootstrap (lazy.nvim auto-bootstraps on first nvim launch) ─
install_lazyvim() {
  info "=== Phase 7: LazyVim ==="
  info "lazy.nvim bootstraps on first nvim launch — no action needed."
  success "Phase 7 complete."
}

# ── PHASE 8: TPM — tmux plugin manager ─────────────────────────────────────────
install_tpm() {
  info "=== Phase 8: TPM ==="
  local TPM_DIR="$HOME/.tmux/plugins/tpm"
  if [ -d "$TPM_DIR" ]; then
    info "TPM already installed — skipping."
    return
  fi
  info "Installing TPM..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  success "Phase 8 complete."
}

# ── PHASE 9: tmux-start.sh ─────────────────────────────────────────────────────
install_tmux_start_script() {
  info "=== Phase 9: tmux-start.sh ==="
  local SCRIPT="$HOME/.tmux/tmux-start.sh"
  if [ -f "$SCRIPT" ]; then
    info "tmux-start.sh already exists — skipping."
    return
  fi
  info "Creating ~/.tmux/tmux-start.sh..."
  mkdir -p "$HOME/.tmux"
  cat > "$SCRIPT" <<'EOF'
#!/bin/zsh
tmux new-session \; source-file ~/.tmux.conf
EOF
  chmod +x "$SCRIPT"
  success "Phase 9 complete."
}

# ── PHASE 10: shell-color-scripts ─────────────────────────────────────────────
install_shell_color_scripts() {
  info "=== Phase 10: shell-color-scripts ==="
  if command -v colorscript &>/dev/null; then
    info "colorscript already installed — skipping."
    return
  fi
  info "Installing shell-color-scripts..."
  local TMP; TMP="$(mktemp -d)"
  git clone --depth=1 https://gitlab.com/dwt1/shell-color-scripts.git "$TMP/shell-color-scripts"
  mkdir -p "$HOME/.local/opt/shell-color-scripts" "$HOME/.local/bin"
  cp -rf "$TMP/shell-color-scripts/colorscripts/." "$HOME/.local/opt/shell-color-scripts/"
  cp "$TMP/shell-color-scripts/colorscript.sh" "$HOME/.local/bin/colorscript"
  chmod +x "$HOME/.local/bin/colorscript"
  sed -i 's|DIR_COLORSCRIPTS="/opt/shell-color-scripts/colorscripts"|DIR_COLORSCRIPTS="$HOME/.local/opt/shell-color-scripts"|' \
    "$HOME/.local/bin/colorscript"
  rm -rf "$TMP"
  success "Phase 10 complete."
}

# ── PHASE 11: gh-notify (requires gh auth — skip if not authenticated) ─────────
install_gh_notify() {
  info "=== Phase 11: gh-notify ==="
  if gh extension list 2>/dev/null | grep -q "gh-notify"; then
    info "gh-notify already installed — skipping."
    return
  fi
  if ! gh auth status &>/dev/null; then
    warn "gh not authenticated — skipping gh-notify."
    warn "Run 'gh auth login' then 'gh extension install meiji163/gh-notify' manually."
    return
  fi
  info "Installing gh-notify..."
  gh extension install meiji163/gh-notify
  success "Phase 11 complete."
}

# ── PHASE 12: Set default shell to zsh ─────────────────────────────────────────
set_default_shell() {
  info "=== Phase 12: Default shell ==="
  local ZSH_PATH; ZSH_PATH="$(command -v zsh)"
  if [ "$SHELL" = "$ZSH_PATH" ]; then
    info "Default shell already zsh — skipping."
    return
  fi
  info "Changing default shell to zsh..."
  sudo chsh -s "$ZSH_PATH" "$(whoami)"
  success "Phase 12 complete (takes effect on next login)."
}

# ── PHASE 13: Apply dotfiles (LAST — after all tools verified) ─────────────────
apply_dotfiles() {
  info "=== Phase 13: Applying dotfiles ==="

  mkdir -p "$HOME/.config"

  link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      info "Already linked: $dst"
      return
    fi
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
      warn "Backing up existing $dst → ${dst}.bak"
      mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    success "Linked $dst → $src"
  }

  link "$REPO_DIR/.zshrc"     "$HOME/.zshrc"
  link "$REPO_DIR/.p10k.zsh"  "$HOME/.p10k.zsh"
  link "$REPO_DIR/.fzf.zsh"   "$HOME/.fzf.zsh"
  link "$REPO_DIR/.tmux.conf" "$HOME/.tmux.conf"
  link "$REPO_DIR/.scripts"          "$HOME/.scripts"
  link "$REPO_DIR/.config/nvim"      "$HOME/.config/nvim"
  link "$REPO_DIR/.config/alacritty" "$HOME/.config/alacritty"
  link "$REPO_DIR/.config/opencode"  "$HOME/.config/opencode"

  success "Phase 13 complete."
}

# ── PHASE 14: Install tmux plugins via TPM ─────────────────────────────────────
install_tmux_plugins() {
  info "=== Phase 14: tmux plugins (TPM) ==="
  if [ -f "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    TMUX='' "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
    success "tmux plugins installed."
  else
    warn "TPM not ready yet — skipping. Run prefix+I inside tmux after first boot."
  fi
  success "Phase 14 complete."
}

# ── PHASE 15: tmux2k custom plugins ────────────────────────────────────────────
link_tmux2k_plugins() {
  info "=== Phase 15: tmux2k custom plugins ==="
  local TMUX2K_PLUGINS_DIR="$HOME/.tmux/plugins/tmux2k/plugins"
  if [ ! -d "$TMUX2K_PLUGINS_DIR" ]; then
    warn "tmux2k plugins dir not found — skipping (run prefix+I in tmux first)."
    return
  fi
  for plugin in calc copilot; do
    local src="$REPO_DIR/.scripts/${plugin}.sh"
    local dst="$TMUX2K_PLUGINS_DIR/${plugin}.sh"
    if [ ! -f "$src" ]; then
      warn "Source not found: $src — skipping."
      continue
    fi
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      info "Already linked: $dst"
    else
      [ -e "$dst" ] && mv "$dst" "${dst}.bak"
      ln -sf "$src" "$dst"
      success "Linked: $dst → $src"
    fi
  done
  success "Phase 15 complete."
}

# ── main ───────────────────────────────────────────────────────────────────────────
main() {
  require_ubuntu

  info "=== Starting bootstrap from $REPO_DIR ==="
  echo ""

  bootstrap_base_tools
  echo ""

  install_apt_packages
  echo ""

  install_zsh
  echo ""

  install_tmux
  echo ""

  install_neovim
  echo ""

  install_nodejs
  echo ""

  install_fnm
  echo ""

  install_golang
  echo ""

  install_rust
  echo ""

  install_homebrew
  echo ""

  install_brew_packages
  echo ""

  install_gh
  echo ""

  install_opencode
  echo ""

  install_jq
  echo ""

  install_nerd_fonts
  echo ""

  install_ohmyzsh
  echo ""

  install_p10k
  echo ""

  install_zsh_plugins
  echo ""

  install_lazyvim
  echo ""

  install_tpm
  echo ""

  install_tmux_start_script
  echo ""

  install_shell_color_scripts
  echo ""

  install_gh_notify
  echo ""

  set_default_shell
  echo ""

  apply_dotfiles
  echo ""

  install_tmux_plugins
  echo ""

  link_tmux2k_plugins
  echo ""

  success "=== Bootstrap complete! ==="
  echo ""
  echo "  Next steps:"
  echo "  1. Log out and back in (or run: exec zsh) for shell changes."
  echo "  2. Open Neovim: nvim   — plugins auto-install on first launch."
  echo "  3. Open tmux and press <prefix>+I to install tmux plugins."
  echo "  4. Run 'p10k configure' to reconfigure the prompt if needed."
  echo "  5. Authenticate: gh auth login"
  echo "  6. Re-run setup after gh auth: bash .scripts/setup.sh"
}

main "$@"

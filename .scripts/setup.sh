#!/usr/bin/env bash
# setup.sh — New Ubuntu device bootstrap
# Installs all dependencies and applies dotfiles from this repo.
# Usage: bash setup.sh [--repo-dir <path>]
#
# Idempotent: safe to run multiple times.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure USER and HOME are always defined (may be unset in Docker/CI)
USER="${USER:-$(id -un)}"
HOME="${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
export USER HOME

# ── helpers ────────────────────────────────────────────────────────────────────
info()    { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
success() { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
warn()    { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
die()     { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

require_ubuntu() {
  if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
    die "This script targets Ubuntu. Detected: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2)"
  fi
}

# ── 1. apt packages ────────────────────────────────────────────────────────────
install_apt_packages() {
  info "Updating apt and installing base packages..."
  sudo apt-get update -qq
  sudo apt-get install -y \
    git curl wget unzip build-essential \
    zsh tmux alacritty \
    zsh-syntax-highlighting \
    fzf ripgrep fd-find \
    fontconfig \
    python3 python3-pip python3-venv \
    golang-go \
    lua5.4 luarocks \
    nodejs npm \
    clangd \
    cmake ninja-build \
    xclip xdotool
  success "apt packages installed."
}

# ── 2. Nerd Fonts (JetBrainsMono — used by p10k nerdfont-v3 + alacritty) ──────
install_nerd_fonts() {
  local FONT_DIR="$HOME/.local/share/fonts"
  if fc-list | grep -qi "JetBrainsMono"; then
    info "JetBrainsMono Nerd Font already installed, skipping."
    return
  fi
  info "Installing JetBrainsMono Nerd Font..."
  local TMP; TMP="$(mktemp -d)"
  wget -qO "$TMP/JetBrainsMono.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  mkdir -p "$FONT_DIR"
  unzip -qo "$TMP/JetBrainsMono.zip" -d "$FONT_DIR/JetBrainsMono"
  fc-cache -f
  rm -rf "$TMP"
  success "JetBrainsMono Nerd Font installed."
}

# ── 3. Homebrew (linuxbrew) ────────────────────────────────────────────────────
install_homebrew() {
  if command -v brew &>/dev/null; then
    info "Homebrew already installed, skipping."
    return
  fi
  info "Installing Homebrew..."
  NONINTERACTIVE=1 bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # shellcheck disable=SC1091
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  success "Homebrew installed."
}

# ── 4. brew packages (eza, zoxide) ────────────────────────────────────────────
install_brew_packages() {
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
  info "Installing brew packages: eza, zoxide..."
  brew install eza zoxide
  success "brew packages installed."
}

# ── 5. Rust / cargo ───────────────────────────────────────────────────────────
install_rust() {
  if command -v cargo &>/dev/null; then
    info "Rust/cargo already installed, skipping."
    return
  fi
  info "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
  success "Rust installed."
}

# ── 6. Oh My Zsh ──────────────────────────────────────────────────────────────
install_ohmyzsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    info "Oh My Zsh already installed, skipping."
    return
  fi
  info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  success "Oh My Zsh installed."
}

# ── 7. Powerlevel10k theme ────────────────────────────────────────────────────
install_p10k() {
  local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [ -d "$P10K_DIR" ]; then
    info "Powerlevel10k already installed, skipping."
    return
  fi
  info "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  success "Powerlevel10k installed."
}

# ── 8. zsh plugins ────────────────────────────────────────────────────────────
install_zsh_plugins() {
  info "Installing zsh plugins..."

  # zsh-autosuggestions (sourced from ~/.zsh/)
  local AUTO_DIR="$HOME/.zsh/zsh-autosuggestions"
  if [ ! -d "$AUTO_DIR" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$AUTO_DIR"
    success "zsh-autosuggestions cloned."
  else
    info "zsh-autosuggestions already present."
  fi

  # fzf-zsh-plugin
  local FZF_ZSH_DIR="$HOME/.zsh/fzf-zsh-plugin"
  if [ ! -d "$FZF_ZSH_DIR" ]; then
    git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin.git "$FZF_ZSH_DIR"
    success "fzf-zsh-plugin cloned."
  else
    info "fzf-zsh-plugin already present."
  fi

  # zsh-syntax-highlighting is installed via apt (see install_apt_packages)
  # verify the expected path exists
  if [ ! -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    warn "zsh-syntax-highlighting not found at expected path. May need: apt install zsh-syntax-highlighting"
  fi

  success "zsh plugins ready."
}

# ── 9. Neovim (latest stable AppImage) ────────────────────────────────────────
install_neovim() {
  if command -v nvim &>/dev/null; then
    info "Neovim already installed ($(nvim --version | head -1)), skipping."
    return
  fi
  info "Installing Neovim (latest stable)..."
  local TMP; TMP="$(mktemp -d)"
  wget -qO "$TMP/nvim.appimage" \
    "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
  chmod +x "$TMP/nvim.appimage"
  # Extract instead of running directly — works without FUSE (required in Docker/CI)
  (cd "$TMP" && ./nvim.appimage --appimage-extract &>/dev/null)
  sudo mv "$TMP/squashfs-root" /opt/nvim
  sudo ln -sf /opt/nvim/usr/bin/nvim /usr/local/bin/nvim
  rm -rf "$TMP"
  success "Neovim installed (extracted to /opt/nvim)."
}

# ── 10. LazyVim bootstrap (lazy.nvim itself) ──────────────────────────────────
# The full nvim config lives in the repo (.config/nvim/). lazy.nvim is
# bootstrapped automatically on first `nvim` launch via lua/config/lazy.lua.
# Nothing to do here — apply_dotfiles symlinks ~/.config/nvim to the repo.
install_lazyvim() {
  info "nvim config comes from the repo — no separate clone needed."
}

# ── 11. TPM — tmux plugin manager ─────────────────────────────────────────────
install_tpm() {
  local TPM_DIR="$HOME/.tmux/plugins/tpm"
  if [ -d "$TPM_DIR" ]; then
    info "TPM already installed, skipping."
    return
  fi
  info "Installing TPM (tmux plugin manager)..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  success "TPM installed."
}

# ── 12. tmux-start.sh helper (used by alacritty) ──────────────────────────────
install_tmux_start_script() {
  local SCRIPT="$HOME/.tmux/tmux-start.sh"
  if [ -f "$SCRIPT" ]; then
    info "tmux-start.sh already exists, skipping."
    return
  fi
  info "Creating ~/.tmux/tmux-start.sh..."
  mkdir -p "$HOME/.tmux"
  cat > "$SCRIPT" <<'EOF'
#!/bin/zsh
tmux new-session \; source-file ~/.tmux.conf
EOF
  chmod +x "$SCRIPT"
  success "tmux-start.sh created."
}

# ── 13. Change default shell to zsh ───────────────────────────────────────────
set_default_shell() {
  local ZSH_PATH
  ZSH_PATH="$(command -v zsh)"
  if [ "$SHELL" = "$ZSH_PATH" ]; then
    info "Default shell is already zsh, skipping."
    return
  fi
  info "Changing default shell to zsh..."
  sudo chsh -s "$ZSH_PATH" "$(whoami)"
  success "Default shell changed to zsh (takes effect on next login)."
}

# ── 14. Apply dotfiles (symlink or copy) ──────────────────────────────────────
apply_dotfiles() {
  info "Applying dotfiles from $REPO_DIR..."

  # Helper: backup existing file then symlink
  link() {
    local src="$1"
    local dst="$2"
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

  # zsh
  link "$REPO_DIR/.zshrc"   "$HOME/.zshrc"
  link "$REPO_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

  # tmux
  link "$REPO_DIR/.tmux.conf" "$HOME/.tmux.conf"

  # alacritty
  mkdir -p "$HOME/.config/alacritty"
  link "$REPO_DIR/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

  # nvim — symlink the entire ~/.config/nvim to the repo's nvim config.
  # The repo contains init.lua, lazyvim.json, stylua.toml and lua/{config,plugins}.
  local NVIM_SRC="$REPO_DIR/.config/nvim"
  local NVIM_DST="$HOME/.config/nvim"
  mkdir -p "$HOME/.config"
  if [ -L "$NVIM_DST" ] && [ "$(readlink -f "$NVIM_DST")" = "$(readlink -f "$NVIM_SRC")" ]; then
    info "Already linked: $NVIM_DST"
  else
    if [ -e "$NVIM_DST" ] && [ ! -L "$NVIM_DST" ]; then
      warn "Backing up existing $NVIM_DST → ${NVIM_DST}.bak"
      mv "$NVIM_DST" "${NVIM_DST}.bak"
    fi
    ln -sf "$NVIM_SRC" "$NVIM_DST"
    success "Linked $NVIM_DST → $NVIM_SRC"
  fi

  # opencode global config
  local OC_SRC="$REPO_DIR/.config/opencode"
  local OC_DST="$HOME/.config/opencode"
  if [ -d "$OC_SRC" ]; then
    mkdir -p "$HOME/.config"
    if [ -L "$OC_DST" ] && [ "$(readlink -f "$OC_DST")" = "$(readlink -f "$OC_SRC")" ]; then
      info "Already linked: $OC_DST"
    else
      [ -e "$OC_DST" ] && mv "$OC_DST" "${OC_DST}.bak"
      ln -sf "$OC_SRC" "$OC_DST"
      success "Linked opencode config: $OC_DST → $OC_SRC"
    fi
  fi

  success "Dotfiles applied."
}

# ── 15. Install tmux plugins via TPM ──────────────────────────────────────────
install_tmux_plugins() {
  info "Installing tmux plugins via TPM..."
  if [ -f "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    # TPM needs TMUX env to be set; run headlessly
    TMUX='' "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
    success "tmux plugins installed."
  else
    warn "TPM not found — skipping plugin install. Run prefix+I inside tmux."
  fi
}

# ── main ──────────────────────────────────────────────────────────────────────
main() {
  require_ubuntu

  info "=== Starting device bootstrap from $REPO_DIR ==="

  install_apt_packages
  install_nerd_fonts
  install_homebrew
  install_brew_packages
  install_rust
  install_ohmyzsh
  install_p10k
  install_zsh_plugins
  install_neovim
  install_lazyvim
  install_tpm
  install_tmux_start_script
  set_default_shell
  apply_dotfiles
  install_tmux_plugins

  echo ""
  success "=== Bootstrap complete! ==="
  echo ""
  echo "  Next steps:"
  echo "  1. Log out and back in (or run: exec zsh) for shell changes."
  echo "  2. Open Neovim: nvim   — plugins will auto-install on first launch."
  echo "  3. Open tmux and press <prefix>+I to confirm tmux plugins are installed."
  echo "  4. Alacritty is configured to start tmux automatically."
  echo "  5. Run 'p10k configure' if you want to reconfigure the prompt."
}

main "$@"

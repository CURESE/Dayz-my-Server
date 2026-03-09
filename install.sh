#!/usr/bin/env bash
# install.sh – OpenClaw macOS installer helper
# Fixes non-interactive Homebrew installation issues when running via:
#   curl -fsSL https://openclaw.ai/install.sh | bash -s -- --install-method git

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

info()    { echo -e "${BLUE}·${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; }

# ── OS guard ─────────────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
  error "This script only supports macOS. For other platforms use the upstream installer:"
  echo "  curl -fsSL https://openclaw.ai/install.sh | bash"
  exit 1
fi

success "Detected: macOS"

# ── Verify admin membership ───────────────────────────────────────────────────
# 'id -Gn' lists all group names for the current user.
if id -Gn | tr ' ' '\n' | grep -qx "admin"; then
  success "Admin rights confirmed for user: $(id -un)"
else
  error "The current user ($(id -un)) is not in the 'admin' group."
  echo "  Ask a macOS administrator to add you, then re-run this script."
  exit 1
fi

# ── Xcode Command Line Tools ──────────────────────────────────────────────────
if ! xcode-select -p &>/dev/null; then
  warn "Xcode Command Line Tools not found – installing…"
  # Install without a TTY by using a touch-file trigger.
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  PROD=$(softwareupdate -l 2>/dev/null \
    | grep -E "^\s*\*.*Command Line" \
    | tail -1 \
    | sed 's/^[^:]*: //')
  if [[ -n "$PROD" ]]; then
    if sudo softwareupdate -i "$PROD" --verbose; then
      rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      success "Xcode Command Line Tools installed."
    else
      rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      warn "Automated CLT install failed (sudo may require a TTY)."
      warn "Open Terminal and run:  xcode-select --install   then re-run this script."
    fi
  else
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    warn "Could not find CLT via softwareupdate. Run 'xcode-select --install' manually."
  fi
else
  success "Xcode Command Line Tools already installed."
fi

# ── Homebrew ──────────────────────────────────────────────────────────────────
install_homebrew() {
  info "Installing Homebrew (non-interactive mode)…"
  # NONINTERACTIVE=1 tells the Homebrew installer to skip the sudo password
  # prompt and accept all defaults – safe because we verified admin membership above.
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

if command -v brew &>/dev/null; then
  success "Homebrew already installed: $(brew --version | head -1)"
else
  info "Homebrew not found – installing…"
  if install_homebrew; then
    # Add Homebrew to PATH for Apple-silicon Macs (/opt/homebrew) and Intel Macs (/usr/local).
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    success "Homebrew installed: $(brew --version | head -1)"
  else
    error "Homebrew installation failed."
    echo ""
    echo "  If you see a sudo/TTY error, install Homebrew manually in a real terminal:"
    echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo "  Then re-run this installer."
    exit 1
  fi
fi

# ── Node.js ───────────────────────────────────────────────────────────────────
if command -v node &>/dev/null; then
  NODE_VERSION=$(node --version)
  success "Node.js already installed: $NODE_VERSION"
else
  info "Node.js not found – installing via Homebrew…"
  brew install node
  success "Node.js installed: $(node --version)"
fi

# ── OpenClaw (git method) ─────────────────────────────────────────────────────
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/openclaw}"
OPENCLAW_REPO="https://github.com/openclaw/openclaw.git"

info "Installing OpenClaw into: $OPENCLAW_DIR"

if [[ -d "$OPENCLAW_DIR/.git" ]]; then
  info "Existing OpenClaw clone found – updating…"
  git -C "$OPENCLAW_DIR" pull --ff-only
  success "OpenClaw updated."
else
  git clone --depth 1 "$OPENCLAW_REPO" "$OPENCLAW_DIR"
  success "OpenClaw cloned."
fi

# Install Node dependencies if a package.json is present.
if [[ -f "$OPENCLAW_DIR/package.json" ]]; then
  info "Installing Node.js dependencies…"
  if npm --prefix "$OPENCLAW_DIR" install --omit=dev; then
    success "Dependencies installed."
  else
    error "npm install failed. Try running manually:"
    echo "  npm --prefix \"$OPENCLAW_DIR\" install --omit=dev"
    exit 1
  fi
fi

# Make the CLI executable and link it into PATH if possible.
if [[ -f "$OPENCLAW_DIR/bin/openclaw" ]]; then
  chmod +x "$OPENCLAW_DIR/bin/openclaw"
  if [[ -d "$(brew --prefix)/bin" ]]; then
    ln -sf "$OPENCLAW_DIR/bin/openclaw" "$(brew --prefix)/bin/openclaw"
    success "openclaw linked to $(brew --prefix)/bin/openclaw"
  fi
fi

echo ""
success "OpenClaw installation complete!"
echo ""
echo "  To get started:"
echo "    openclaw --help"
echo ""
echo "  If 'openclaw' is not in your PATH, add the following to your shell profile:"
if [[ -x /opt/homebrew/bin/brew ]]; then
  echo '    eval "$(/opt/homebrew/bin/brew shellenv)"'
else
  echo '    export PATH="/usr/local/bin:$PATH"'
fi

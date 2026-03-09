# Dayz-my-Server
单机文件存储

## Installing OpenClaw on macOS

The upstream OpenClaw installer (`curl -fsSL https://openclaw.ai/install.sh | bash`) can
fail on macOS when Homebrew is not already installed, because the Homebrew installer
requires an interactive TTY to request a sudo password—something that a piped `bash`
session does not provide.

### Quick fix

Use the helper script in this repository instead.  It sets `NONINTERACTIVE=1` when
calling the Homebrew installer, which allows Homebrew to install without requiring
an interactive sudo prompt (your user must still be a member of the `admin` group,
which any standard macOS account is by default):

```bash
curl -fsSL https://raw.githubusercontent.com/CURESE/Dayz-my-Server/main/install.sh | bash
```

Or clone the repo and run it directly:

```bash
git clone https://github.com/CURESE/Dayz-my-Server.git
cd Dayz-my-Server
bash install.sh
```

### Prerequisites

| Requirement | How to check |
|-------------|--------------|
| macOS (any version with Xcode CLT support) | `uname -s` → `Darwin` |
| Admin group membership | `id -Gn \| grep admin` |
| Xcode Command Line Tools | `xcode-select -p` (the script installs them if missing) |
| Internet access | required to download Homebrew and OpenClaw |

> **Note:** Node.js v18+ is recommended.  If you already have Node installed
> (e.g. `node -v` returns a version), the script will use it and skip the
> Homebrew Node.js installation step.

### Manual Homebrew installation

If you prefer to install Homebrew yourself before running the OpenClaw installer:

```bash
# Install Homebrew interactively (open a real terminal – not a piped session)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Then run the upstream OpenClaw installer
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --install-method git
```

### Troubleshooting

| Symptom | Fix |
|---------|-----|
| `✗ Installing Homebrew failed — re-run with --verbose for details` | Run `install.sh` from this repo; it uses `NONINTERACTIVE=1` to bypass the TTY requirement |
| `Need sudo access on macOS` | Confirm you are in the admin group: `id -Gn \| grep admin` |
| `openclaw: command not found` after install | Add Homebrew to your PATH: `eval "$(/opt/homebrew/bin/brew shellenv)"` (Apple Silicon) or `export PATH="/usr/local/bin:$PATH"` (Intel) |

# Doms Dotfiles

Configuration management system using MItamae for cross-platform dotfiles and
system setup.

## Quick Installation

### Linux/macOS

```sh
curl https://raw.githubusercontent.com/dsisnero/doms_dotfiles/main/install | bash -s
```

### Windows

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
iwr -useb https://raw.githubusercontent.com/dsisnero/doms_dotfiles/main/install.ps1 | iex
```

**Note for Windows:** If the install script appears cached, use:

```powershell
iwr -Headers @{"Cache-Control"="no-cache"} -useb https://raw.githubusercontent.com/dsisnero/doms_dotfiles/main/install.ps1 | iex
```

## Development & Deployment Workflow

### Basic Usage

```bash
# Full deployment (all cookbooks)
./bin/deploy

# Deploy with debug logging
./bin/deploy --debug

# Deploy specific cookbook(s)
./bin/deploy git
./bin/deploy git dotfiles rust

# Deploy with role and hostname
./bin/deploy --role development --host pi-dev
```

### Deployment Flow (`./bin/deploy --debug`)

#### 1. **Argument Parsing** (`bin/deploy:21-53`)

- Sets `DEBUG=true`, `ROLE` and `HOSTNAME` from `--role`/`--host` flags
- Exports `ROLE` and `HOSTNAME` as environment variables

#### 2. **Setup Phase** (`bin/deploy:57` → `bin/setup`)

- Downloads `mitamae` binary if missing (architecture-specific)
- **SSH URL detection**: Checks `.gitmodules` and git config for SSH URLs → runs
  `git submodule sync` if found
- Initializes submodules with `git submodule update --init --recursive`

#### 3. **Mitamae Execution** (`bin/deploy:59-68`)

- Loads `github_binary` plugin via `RUBYLIB`
- **macOS**: Runs mitamae directly
- **Linux/Raspberry Pi**: Uses `sudo -E` with environment preservation

#### 4. **Full Deployment Path** (no cookbooks specified)

- Runs `mitamae local --shell /bin/bash -l debug lib/recipe.rb`

#### 5. **Core Recipe Flow** (`lib/recipe.rb:1-14`)

```ruby
include_recipe "recipe_helper"           # Loads all helpers
if node[:platform] == "pop"             # Pop!→Ubuntu remap
  node.reverse_merge!(platform: "ubuntu")
end
include_role node[:platform]            # e.g., "debian", "ubuntu", "darwin"
if node[:role]                          # e.g., "development", "media"
  include_role node[:role]
end
```

#### 6. **Recipe Helper Initialization** (`lib/recipe_helper.rb:6-376`)

- **Helper Definitions**: `include_cookbook`, `include_role`,
  `include_definition`
- **Platform Detection**: `windows?`, `wsl?`, `version_less_than?`
- **GitHub API helpers**: `github_latest_version`, `compute_target_info`

#### 7. **Node Initialization** (`init_node` line 373)

1. **Role Detection** (`detect_role` lines 68‑89):
   - `ENV["ROLE"]` (set by `--role` flag) takes precedence
   - Hostname-based fallback:
     - `pi-dev*` → `development`
     - `pi-media*` → `media`
     - `pi-minimal*` → `minimal`
     - `pi-ha*` → `home-assistant`
2. **Hostname Setting** (`set_hostname` lines 91‑132):
   - Uses `ENV["HOSTNAME"]` (set by `--host` flag)
   - Platform-specific commands (`hostnamectl`, `scutil`)
3. **Node Variables** (lines 134‑186):
   - `user`, `home`, `group`, XDG directories
   - Paths: `repos`, `my_repos`, `doms_dotfiles`
   - Sets `node[:role]` from detection

#### 8. **Role Execution Chain**

##### **Platform Role** (e.g., `roles/debian/default.rb`)

- Removes `nano`, installs Raspberry Pi packages on ARM
- Updates packages (`apt update && apt upgrade`)
- **Includes base role**: `include_role("base")`

##### **Base Role** (`roles/base/default.rb`)

- Installs core tools via `mise` (node, lua‑language‑server, fd, rg, etc.)
- Includes **cookbooks**: `keepassxc`, `sudo_nopassword`, `mise`, `keychain`,
  `dotfiles`, `git`, `rust`, `helix`, `golang`, `neovim`, `zsh`, `mysql`,
  `chrome`, `calibre`, `podman`, etc.

##### **Functional Role** (if `node[:role]` set)

- `roles/development/default.rb`, `roles/media/default.rb`, etc.
- Role-specific packages and configurations

#### 9. **Debug Output**

- Platform detection logged at start (`lib/recipe.rb:2`)
- Node info dumped after initialization (`lib/recipe_helper.rb:375`)
- All mitamae operations run at `debug` log level

### Individual Cookbook Deployment

```bash
./bin/deploy git
```

- `bin/normalize_cookbooks` converts `"git"` → `"cookbooks/git/default.rb"`
- Runs `mitamae local -l debug lib/recipe_helper.rb cookbooks/git/default.rb`
- Same initialization, but only the specified cookbook executed after helpers

## Platform Support

### Linux

- **Debian-based**: Debian, Ubuntu, Mint, Pop! (remapped to Ubuntu)
- **RPM-based**: RedHat, Fedora, Amazon Linux
- **Other**: Arch, OpenSUSE
- **Raspberry Pi**: ARM detection, `raspi-config`, SPI/I2C enablement

### macOS

- Darwin support via Homebrew packages
- Hostname management via `scutil`

### Windows

- Limited support via `windows_node.rb`
- PowerShell-based installation

## Role System

### Available Roles

- **development**: Development tools and environments
- **media**: Media center packages (Plex, Jellyfin, etc.)
- **minimal**: Minimal system setup
- **home-assistant**: Home Assistant automation platform

### Role Detection Priority

1. `--role` command-line flag
2. Hostname pattern matching:
   - `pi-dev*` → `development`
   - `pi-media*` → `media`
   - `pi-minimal*` → `minimal`
   - `pi-ha*` → `home-assistant`

## Cookbook Structure

### Location

```text
cookbooks/
├── git/           # Git configuration
├── dotfiles/      # Dotfile management
├── rust/          # Rust toolchain
├── neovim/        # Neovim editor
└── ...
```

### Adding New Cookbooks

1. Create `cookbooks/NAME/default.rb`
2. Follow existing patterns for idempotency
3. Use helper methods from `lib/recipe_helper.rb`
4. Test with `./bin/deploy NAME`

## Plugin Submodules

### Current Plugins

- `plugins/itamae-plugin-recipe-rust` - Rust installation
- `plugins/mitamae-plugin-resource-github_binary` - GitHub binary downloads
- `plugins/mitamae-plugin-resource-apt-repository` - APT repository management
- `plugins/mitamae-plugin-resource-apt_keyring` - APT keyring management
- `plugins/itamae-plugin-resource-flatpak` - Flatpak support

### SSH to HTTPS Migration

All plugin submodules now use HTTPS URLs for public cloning. The `bin/setup`
script automatically detects SSH URLs and runs `git submodule sync` to update
them.

## Troubleshooting

### Submodule Cloning Issues

```bash
# If SSH authentication fails on fresh Raspberry Pi:
git submodule sync
git submodule update --init --recursive

# Check for SSH URLs:
grep -E 'git@|ssh://' .gitmodules
git config --get-regexp '^submodule\..*\.url' | grep -E 'git@|ssh://'
```

### Mitamae Binary Issues

```bash
# Remove and re-download:
rm bin/mitamae
./bin/setup
```

### Debugging Deployment

```bash
# Maximum verbosity:
./bin/deploy --debug 2>&1 | less

# Specific cookbook debug:
./bin/deploy --debug git
```

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `ROLE` | Deployment role | Hostname-based detection |
| `HOSTNAME` | System hostname | Current hostname |
| `XDG_CONFIG_HOME` | Config directory | `~/.config` |
| `XDG_DATA_HOME` | Data directory | `~/.local/share` |
| `XDG_CACHE_HOME` | Cache directory | `~/.cache` |
| `XDG_STATE_HOME` | State directory | `~/.local/state` |

## Project Structure

```text
.
├── bin/                    # Deployment scripts
├── cookbooks/             # MItamae cookbooks
├── roles/                 # Platform and functional roles
├── plugins/               # MItamae plugins (submodules)
├── lib/                   # Helper libraries
├── config/                # Configuration templates
├── definitions/           # MItamae definitions
└── templates/             # Template files
```

## Documentation

- **AGENTS.md**: AI coding assistant guide with project-specific commands and
  conventions
- **TEST_DEPLOYMENT.md**: Testing procedures and verification workflows
- **PRE_COMMIT_FRAMEWORK.md**: Pre-commit hook configuration and usage
- **docs/**: Design documents and planning notes

For detailed development workflows and coding standards, refer to
[AGENTS.md](./AGENTS.md).

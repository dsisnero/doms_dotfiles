# Role System Design

## Overview

Add role-based deployment to MItamae cookbooks for Raspberry Pi management.
Roles allow different Pi setups (development, media, minimal, home-assistant) to
share platform defaults while adding role-specific cookbooks.

## Current System

- `bin/deploy` runs mitamae with either full deployment (`lib/recipe.rb`) or
  specific cookbooks via `lib/recipe_helper.rb`
- `normalize_cookbooks` already supports `roles/` directory lookup
- `recipe_helper.rb` has `include_role` method that includes
  `roles/<name>/default.rb`
- `lib/recipe.rb` includes role based on platform (`node[:platform]`)
- No roles directory exists yet

## Design Decisions

### Role Detection

1. **Command-line argument**: `--role` flag for `bin/deploy`
2. **Hostname fallback**: If no role provided, infer from hostname prefix:
   - `pi-dev` → `development`
   - `pi-media` → `media`
   - `pi-minimal` → `minimal`
   - `pi-ha` → `home-assistant`
3. **Environment variable**: Role passed via `ROLE` environment variable to
   mitamae
4. **Node attribute**: Role stored in `node[:role]` for use in recipes

### Role Structure

- `roles/` directory with subdirectories for each role
- Each role contains `default.rb` that includes relevant cookbooks via
  `include_cookbook`
- Platform roles remain as `roles/<platform>/default.rb` (to be created as
  needed)
- **Minimal role**: Empty `default.rb` (no additional cookbooks beyond platform
  defaults)

### Role Integration

- **Combine with platform role**: Platform role included first, then
  role-specific additions
- This ensures platform-specific defaults (package manager setup, base packages)
  apply to all roles
- Role cookbooks can override platform defaults if needed

### Platform Detection for Raspberry Pi

- Raspberry Pi OS is detected as `debian` platform by mitamae/Specinfra
- Created `roles/debian/default.rb` with base packages and Raspberry Pi specific
  utilities
- ARM architecture detection adds raspi-config, pi-bluetooth, and enables
  SPI/I2C
- Platform role combined with role-specific cookbooks (development, media, etc.)

### Implementation Changes

#### `bin/deploy`

- Add `--role` flag parsing
- Add `--host` flag for setting system hostname
- Pass role via `ROLE` environment variable in `run_mitamae` function
- Pass hostname via `HOSTNAME` environment variable
- Maintain backward compatibility (no role → platform-only deployment)

#### `recipe_helper.rb`

- Add `detect_role` method that:
  - Checks `ENV['ROLE']`
  - Falls back to hostname prefix mapping
  - Stores result in `node[:role]`
- Add `set_hostname` method that sets system hostname when `ENV['HOSTNAME']` is
  provided
  - Platform-specific implementation (hostnamectl for Linux, scutil for macOS)
  - Idempotent check to avoid unnecessary changes
- Call `detect_role` from `init_node`
- Call `set_hostname` after node initialization
- Modify `include_role` to support combined inclusion (platform + specific role)

#### `lib/recipe.rb`

- Include platform role via `include_role node[:platform]`
- Include detected role if present: `include_role node[:role] if node[:role]`

#### Hostname Mapping

- Hardcoded mapping in `detect_role` method
- Simple prefix matching: hostname starting with `pi-` followed by role
  identifier

## Roles Definition

### `roles/development/default.rb`

```ruby
# Development role - include development-specific cookbooks
# Base role already includes git, rust, golang, python, ruby, crystal, zig, etc.
# Add additional development tools and services

include_cookbook "docker"
include_cookbook "postgresql"
include_cookbook "nodejs"
include_cookbook "java"
include_cookbook "terraform"
include_cookbook "aws-cli"
include_cookbook "github-cli"
include_cookbook "ollama"
include_cookbook "ngrok"
include_cookbook "shellcheck"
include_cookbook "hadolint"
include_cookbook "openssh"
include_cookbook "clang"
include_cookbook "llvm"
```

### `roles/media/default.rb`

```ruby
# Media role - include media-related cookbooks
package "vlc"
package "handbrake"
package "ffmpeg"

# Additional media packages for Debian-based systems
if platform_family == "debian"
  package "ubuntu-restricted-extras"
end
```

### `roles/home-assistant/default.rb`

```ruby
# Home Assistant automation role
package "mosquitto"

# Node-RED for flow-based programming
if platform_family == "debian"
  package "node-red"
end

# Additional home automation packages can be added here
# Consider adding cookbooks for home-assistant, zigbee2mqtt, etc.
```

### `roles/minimal/default.rb`

```ruby
# Minimal role - no additional cookbooks beyond platform defaults
```

## Usage Examples

```bash
# Deploy with explicit role
./bin/deploy --role development

# Deploy with hostname inference (hostname: pi-media)
./bin/deploy

# Deploy specific cookbooks (existing behavior preserved)
./bin/deploy git dotfiles

# Set system hostname and deploy with role
./bin/deploy --role development --host pi-dev

# Set hostname only (role inferred from hostname)
./bin/deploy --host pi-media
```

## Future Considerations

1. **Role-specific attributes**: Allow role to set node attributes
2. **Platform-specific roles**: Nested roles for platform variations
3. **Configuration file**: YAML mapping for hostname→role relationships
4. **Role validation**: Verify role exists before attempting inclusion

## Success Criteria

1. Role detection works via command line and hostname
2. Platform defaults apply to all roles
3. Role-specific cookbooks are included correctly
4. Minimal role includes only platform defaults
5. Backward compatibility maintained for existing deployments

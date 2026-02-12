# Role System Design

## Overview

Add role-based deployment to MItamae cookbooks for Raspberry Pi management. Roles allow different Pi setups (development, media, minimal, home-assistant) to share platform defaults while adding role-specific cookbooks.

## Current System

- `bin/deploy` runs mitamae with either full deployment (`lib/recipe.rb`) or specific cookbooks via `lib/recipe_helper.rb`
- `normalize_cookbooks` already supports `roles/` directory lookup
- `recipe_helper.rb` has `include_role` method that includes `roles/<name>/default.rb`
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
3. **Environment variable**: Role passed via `ROLE` environment variable to mitamae
4. **Node attribute**: Role stored in `node[:role]` for use in recipes

### Role Structure
- `roles/` directory with subdirectories for each role
- Each role contains `default.rb` that includes relevant cookbooks via `include_cookbook`
- Platform roles remain as `roles/<platform>/default.rb` (to be created as needed)
- **Minimal role**: Empty `default.rb` (no additional cookbooks beyond platform defaults)

### Role Integration
- **Combine with platform role**: Platform role included first, then role-specific additions
- This ensures platform-specific defaults (package manager setup, base packages) apply to all roles
- Role cookbooks can override platform defaults if needed

### Implementation Changes

#### `bin/deploy`
- Add `--role` flag parsing
- Pass role via `ROLE` environment variable in `run_mitamae` function
- Maintain backward compatibility (no role → platform-only deployment)

#### `recipe_helper.rb`
- Add `detect_role` method that:
  - Checks `ENV['ROLE']`
  - Falls back to hostname prefix mapping
  - Stores result in `node[:role]`
- Call `detect_role` from `init_node`
- Modify `include_role` to support combined inclusion (platform + specific role)

#### `lib/recipe.rb`
- Include platform role via `include_role node[:platform]`
- Include detected role if present: `include_role node[:role] if node[:role]`

#### Hostname Mapping
- Hardcoded mapping in `detect_role` method
- Simple prefix matching: hostname starting with `pi-` followed by role identifier

## Roles Definition

### `roles/development/default.rb`
```ruby
include_cookbook "git"
include_cookbook "dotfiles"
include_cookbook "gcm"
# Add development-specific cookbooks
```

### `roles/media/default.rb`
```ruby
include_cookbook "media-packages"
# Add media-specific cookbooks
```

### `roles/home-assistant/default.rb`
```ruby
include_cookbook "home-assistant"
# Add home automation cookbooks
```

### `roles/minimal/default.rb`
```ruby
# Empty - only platform defaults apply
```

## Usage Examples

```bash
# Deploy with explicit role
./bin/deploy --role development

# Deploy with hostname inference (hostname: pi-media)
./bin/deploy

# Deploy specific cookbooks (existing behavior preserved)
./bin/deploy git dotfiles
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
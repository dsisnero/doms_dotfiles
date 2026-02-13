# GitHub Asset Resource for MItamae

Downloads release assets from GitHub repositories with platform-aware selection.

## Features

- Downloads release assets from GitHub
- Supports both latest release and specific versions
- Automatically selects assets based on platform and architecture
- Sets file permissions and ownership

## Attributes

| Attribute       | Required | Default    | Description                                  |
| --------------- | -------- | ---------- | -------------------------------------------- |
| `repo`          | Yes      | -          | GitHub repository (owner/repo)               |
| `version`       | No       | `'latest'` | Release version (`'latest'` or specific tag) |
| `asset_pattern` | Yes      | -          | Filename pattern with placeholders           |
| `download_path` | Yes      | -          | Local path to save the asset                 |
| `user`          | No       | -          | File owner user                              |
| `group`         | No       | -          | File owner group                             |
| `mode`          | No       | -          | File permissions (octal string)              |

## Pattern Placeholders

Use these placeholders in `asset_pattern`:

- `:version`: Release version
- `:os`: Operating system (e.g., `ubuntu`)
- `:arch`: Architecture (e.g., `x86_64`)

## Usage Example

```ruby
github_asset "Download binary" do
  repo "owner/repo"
  version "latest"  # or "v1.2.3"
  asset_pattern "app-:version-:os-:arch.tar.gz"
  download_path "/usr/local/bin/app"
  user "root"
  group "root"
  mode "755"
end
```

## Requirements

- MItamae v1.10.1+
- `http_request` resource (built-in)
- JSON parsing support in MItamae

## Installation

1. Add as submodule to your repository:

   ```bash
   git submodule add https://github.com/yourusername/mitamae-plugin-resource-github_asset plugins/mitamae-plugin-resource-github_asset
   ```

2. The plugin will be automatically loaded by MItamae when placed in the
   `plugins` directory

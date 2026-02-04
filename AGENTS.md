# AGENTS.md - AI Coding Assistant Guide

## Project Overview

This is a Ruby project using Rubocop for code formatting and style enforcement.

## Commands

### Development

- **Run tests**: `bundle exec rspec` or `rake test`
- **Format code**: `rubocop --fix`
- **Check code style**: `rubocop`
- **Install dependencies**: `bundle install`

### Common Tasks

- **Start development server**: `rails server` or `bundle exec rails s`
- **Run console**: `rails console` or `bundle exec rails c`
- **Database migrations**: `rails db:migrate`
- **Run specific tests**: `bundle exec rspec spec/path/to/test_spec.rb`

## Code Style

### Ruby Style Guide

- Follow Rubocop defaults and project-specific `.rubocop.yml` configuration
- Use 2-space indentation
- Use snake_case for methods and variables
- Use CamelCase for classes and modules
- Prefer single quotes for strings unless interpolation is needed
- Use trailing commas in multiline arrays and hashes

### File Organization

- `app/` - Main application code (models, controllers, views, etc.)
- `spec/` or `test/` - Test files
- `config/` - Configuration files
- `lib/` - Library code
- `db/` - Database migrations and schema

## Testing

### RSpec Patterns

- Test files should end with `_spec.rb`
- Use descriptive test names with `describe` and `it` blocks
- Follow the "Given-When-Then" pattern for test structure
- Use factories (FactoryBot) for test data
- Mock external dependencies when appropriate

### Test Commands

- Run all tests: `bundle exec rspec`
- Run specific file: `bundle exec rspec spec/models/user_spec.rb`
- Run specific line: `bundle exec rspec spec/models/user_spec.rb:15`
- Run with coverage: `COVERAGE=true bundle exec rspec`

## Dependencies

### Gem Management

- Dependencies are managed in `Gemfile`
- Run `bundle install` after adding new gems
- Use `bundle exec` to run commands with the correct gem versions
- Development/test gems should be in appropriate groups

## Workflow for AI Assistant

### When Making Changes

1. **Read existing code** to understand patterns and conventions
2. **Write tests** for new functionality
3. **Implement the feature** following Rubocop style
4. **Format code**: Always run `rubocop --fix` after editing files
5. **Run tests**: Verify changes with `bundle exec rspec`
6. **Check for regressions**: Run full test suite

### Code Quality

- Always run `rubocop --fix` before committing changes
- Ensure all tests pass before marking work complete
- Follow existing patterns in the codebase
- Add proper error handling and validation
- Write clean, readable code without unnecessary comments

### File Naming

- Model files: `app/models/user.rb`
- Controller files: `app/controllers/users_controller.rb`
- Test files: `spec/models/user_spec.rb`, `spec/controllers/users_controller_spec.rb`
- Helper files: `app/helpers/users_helper.rb`

## Security

- Never commit secrets, API keys, or credentials
- Use environment variables for sensitive configuration
- Follow Rails security best practices
- Validate user input and use parameter sanitization

## Common Patterns

### Rails Applications

- Follow RESTful conventions for controllers
- Use strong parameters in controllers
- Keep business logic in models or service objects
- Use concerns for shared functionality
- Follow the "fat models, skinny controllers" principle

### Database

- Use migrations for schema changes
- Add indexes for performance on foreign keys and frequently queried columns
- Use validations in models
- Follow ActiveRecord conventions

This guide helps AI assistants understand the project structure, coding standards, and development workflow for this Ruby project.

## MItamae Cookbook Patterns

This project uses MItamae for configuration management. Cookbooks are located in `cookbooks/` directory.

### Basic Cookbook Structure

```ruby
# cookbooks/example/default.rb

# Helper methods can be defined in a module
module ExampleHelper
  def example_installed_version
    # Check installed version logic
    # Return version string or nil if not installed
  end

  def example_latest_version
    # Fetch latest version from external source
    # Return version string or nil if unavailable
  end
end

::MItamae::RecipeContext.include ExampleHelper
::MItamae::ResourceContext.include ExampleHelper

# Main recipe logic
case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  # Linux-specific installation
  home = node[:home]
  user = node[:user]

  # Install using platform-specific package manager or direct download
when "darwin"
  # macOS-specific installation (Homebrew)
  package "example-tool"
when "windows"
  # Windows-specific installation
  log "Not implemented"
end
```

### Version Management Pattern (like rpi-imager)

For tools that need version checking and automatic updates:

1. **Define helper methods** to check installed and latest versions
2. **Use `version_less_than?`** from PlatformHelpers for semantic version comparison
3. **Download only when needed** to avoid unnecessary network calls
4. **Use cache directory** (`~/.cache/`) instead of `/tmp` for user-specific downloads
5. **Add error handling** with rescue blocks for network/execution failures

Example from `cookbooks/rpi_imager/default.rb`:

```ruby
def rpi_imager_installed_version
  begin
    case node[:platform]
    when "debian", "ubuntu", "mint", "pop"
      appimage_path = "#{node[:home]}/.local/bin/rpi-imager"
      if File.exist?(appimage_path)
        result = run_command("#{appimage_path} --version 2>/dev/null", error: false)
        if result.success?
          match = result.stdout.match(/v(\d+\.\d+\.\d+)/)
          return match[1] if match
        end
      end
    # ... other platforms
    end
  rescue => e
    MItamae.logger.warn "Failed to get installed version: #{e.message}"
  end
  nil
end

def rpi_imager_latest_appimage_info
  begin
    max_retries = 3
    retry_count = 0

    while retry_count < max_retries
      cmd = "curl -s https://downloads.raspberrypi.com/imager/"
      result = run_command(cmd, error: false)

      if result.success?
        html = result.stdout
        appimages = []

        # Parse HTML for download links
        html.scan(/href="(imager_\d+\.\d+\.\d+_amd64\.AppImage)"/) do |match|
          filename = match[0]
          version_match = filename.match(/imager_(\d+\.\d+\.\d+)_amd64\.AppImage/)
          if version_match
            appimages << {version: version_match[1], filename: filename}
          end
        end

        # Find highest version
        unless appimages.empty?
          highest = appimages.first
          appimages.each do |appimage|
            if version_less_than?(highest[:version], appimage[:version])
              highest = appimage
            end
          end
          return highest
        end
      end

      retry_count += 1
      sleep 2 if retry_count < max_retries
    end
  rescue => e
    MItamae.logger.warn "Failed to get latest version: #{e.message}"
  end
  nil
end
```

### Resource Patterns

- **Use `directory`** for creating directories with proper permissions
- **Use `http_request`** for downloading files (not `curl`/`wget` in execute blocks)
- **Use `execute` with `not_if`/`only_if`** to make operations idempotent
- **Chain notifications** (`notifies`) for sequential operations
- **Set user ownership** for user-specific files/directories

### Platform Support

- **Linux (deb-based)**: `"debian", "ubuntu", "mint", "pop"`
- **macOS**: `"darwin"` or `"osx"`
- **Windows**: `"windows"`

### Best Practices

1. **Idempotency**: Ensure cookbooks can run multiple times without side effects
2. **Error handling**: Wrap external commands and network calls in rescue blocks
3. **Logging**: Use `MItamae.logger.info/warn` for debugging
4. **User-specific paths**: Use `node[:home]` and `node[:user]` variables
5. **Cache management**: Store downloads in user's cache directory
6. **Cleanup**: Remove old installations when switching methods (e.g., snap → AppImage)

### Available Helpers

- `version_less_than?(v1, v2)`: Compare semantic versions
- `github_latest_version(repo)`: Get latest GitHub release tag
- `run_command(cmd, error: false)`: Execute shell command safely
- `sudo(user)`: Generate sudo command prefix

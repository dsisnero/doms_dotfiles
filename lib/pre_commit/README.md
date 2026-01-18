# mruby Pre-Commit Framework

A lightweight, cross-platform pre-commit validation system built for mruby-based projects.

## Overview

This framework provides a simple yet powerful way to enforce code quality standards before commits. It's designed to work within the constraints of mruby while providing essential validation features.

## Features

- **Cross-platform compatibility** - Works on Windows, macOS, and Linux
- **Lightweight** - Minimal dependencies, optimized for mruby
- **Extensible** - Easy to add custom validators
- **Automatic fixes** - Some validators can automatically fix issues
- **Git integration** - Seamless integration with git hooks

## Built-in Validators

### Whitespace Validator

- Removes trailing whitespace
- Converts line endings to Unix format
- Ensures files end with a newline
- Automatically fixes issues

### Line Length Validator

- Enforces maximum line length (default: 80 characters)
- Smart handling of comments and URLs
- Skips binary and minified files

### Syntax Validator

- Basic Ruby syntax validation
- Checks for balanced brackets, braces, and parentheses
- Detects unterminated strings and comments

## Installation

1. Copy the `lib/pre_commit` directory to your project
2. Run the setup script:

```bash
ruby bin/setup-pre-commit install
```

## Usage

### Basic Configuration

```ruby
require 'pre_commit'

PreCommit.configure do |config|
  config.add_validator(PreCommit::Validators::Whitespace.new)
  config.add_validator(PreCommit::Validators::LineLength.new(79))
  config.add_validator(PreCommit::Validators::Syntax.new)

  config.exclude('vendor/**/*')
  config.exclude('*.min.js')
end

PreCommit.run
```

### Custom Validators

Create custom validators by implementing a `validate` method:

```ruby
class CustomValidator
  def validate(file_path)
    return unless file_path.end_with?('.rb')

    content = File.read(file_path)

    if content.include?('TODO')
      "Found TODO in #{file_path} - please address before committing"
    end
  end
end

PreCommit.config.add_validator(CustomValidator.new)
```

### Manual Testing

Test the pre-commit framework manually:

```bash
ruby bin/pre-commit
```

## Configuration

The framework automatically loads patterns from:

- `.gitignore` - Exclude patterns
- `.pre-commit-config` - Custom configuration (future)

## Integration with Build System

This framework is designed to be integrated into the mruby-based build system:

```ruby
# In your build script
require 'pre_commit'

# Configure and run as part of build process
if PreCommit.run
  puts "Pre-commit checks passed"
  # Continue with build
else
  puts "Pre-commit checks failed"
  exit 1
end
```

## Troubleshooting

### Skipping Pre-commit Checks

```bash
git commit --no-verify
```

### Manual Hook Installation

If the setup script doesn't work, manually copy:

```bash
cp bin/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

## License

This framework is part of the mruby dotfiles project and follows the same licensing terms.
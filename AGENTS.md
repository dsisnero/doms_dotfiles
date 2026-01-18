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
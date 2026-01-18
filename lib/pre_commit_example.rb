# Example usage of mruby pre-commit framework

require_relative 'pre_commit'

# Configure pre-commit with built-in validators
PreCommit.configure do |config|
  # Add built-in validators
  config.add_validator(PreCommit::Validators::Whitespace.new)
  config.add_validator(PreCommit::Validators::LineLength.new(79))
  config.add_validator(PreCommit::Validators::Syntax.new)

  # Exclude common patterns
  config.exclude('vendor/**/*')
  config.exclude('*.min.js')
  config.exclude('*.min.css')
  config.exclude('*.png')
  config.exclude('*.jpg')
  config.exclude('*.gif')
  config.exclude('*.pdf')
end

# Custom validator example
class CustomRubyValidator
  def validate(file_path)
    return unless file_path.end_with?('.rb')

    content = File.read(file_path)

    # Check for TODO comments
    if content.include?('TODO') || content.include?('FIXME')
      "Found TODO/FIXME in #{file_path} - please address before committing"
    end
  end
end

# Add custom validator
PreCommit.config.add_validator(CustomRubyValidator.new)

# Run pre-commit checks
if PreCommit.run
  puts "✅ Pre-commit checks passed!"
else
  puts "❌ Pre-commit validation failed"
  exit 1
end
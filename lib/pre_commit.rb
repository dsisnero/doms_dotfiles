# mruby Pre-Commit Framework
# Lightweight pre-commit validation system for mruby-based projects

module PreCommit
  class Config
    def initialize
      @validators = []
      @exclude_patterns = []
      load_dotfiles
    end

    def add_validator(validator)
      @validators << validator
    end

    def exclude(pattern)
      @exclude_patterns << pattern
    end

    def validators
      @validators
    end

    def exclude_patterns
      @exclude_patterns
    end

    def load_dotfiles
      # Load from .gitignore
      load_gitignore if File.exist?('.gitignore')
      load_pre_commit_config if File.exist?('.pre-commit-config')
    end

    private

    def load_gitignore
      File.readlines('.gitignore').each do |line|
        line.strip!
        exclude(line) unless line.empty? || line.start_with?('#')
      end
    end

    def load_pre_commit_config
      # Custom pre-commit configuration
      # Implementation depends on format preference
      if File.exist?('.pre-commit-config')
        # Could load YAML, JSON, or custom format
        # For now, we'll keep it simple
      end
    end
  end

  class Runner
    def initialize(config)
      @config = config
      @errors = []
      @fixes = []
    end

    def run(files = tracked_files)
      filtered_files = filter_files(files)

      @config.validators.each do |validator|
        filtered_files.each do |file|
          result = validator.validate(file)
          if result.is_a?(String) && result.start_with?('Fixed:')
            @fixes << result
          elsif result.is_a?(String)
            @errors << result
          end
        end
      end

      # Report fixes
      @fixes.each { |fix| puts "✓ #{fix}" } unless @fixes.empty?

      @errors.empty?
    end

    def errors
      @errors
    end

    def fixes
      @fixes
    end

    private

    def tracked_files
      # Get list of files staged for commit
      # Cross-platform implementation
      if windows?
        `git diff --cached --name-only`.lines.map(&:strip)
      else
        `git diff --cached --name-only --diff-filter=ACM`.lines.map(&:strip)
      end
    rescue
      [] # Fallback if git not available
    end

    def filter_files(files)
      files.reject do |file|
        @config.exclude_patterns.any? { |pattern| File.fnmatch(pattern, file) }
      end
    end

    def windows?
      RUBY_PLATFORM =~ /mswin|mingw|cygwin/
    end
  end

  class << self
    def configure
      @config ||= Config.new
      yield @config if block_given?
      @config
    end

    def run(files = nil)
      runner = Runner.new(config)
      success = runner.run(files)

      unless success
        runner.errors.each { |error| puts "✗ #{error}" }
        puts "\nPre-commit validation failed. Please fix the issues above."
      end

      success
    end

    def config
      @config || configure
    end
  end
end

# Load built-in validators
require_relative 'pre_commit/validators/whitespace'
require_relative 'pre_commit/validators/line_length'
require_relative 'pre_commit/validators/syntax'

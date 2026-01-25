# Whitespace validator for mruby pre-commit framework
module PreCommit
  module Validators
    class Whitespace
      def validate(file_path)
        return unless File.file?(file_path)

        # Skip binary files
        return if binary_file?(file_path)

        content = File.read(file_path)
        original_content = content.dup

        # Remove trailing whitespace
        content.gsub!(/[ \t]+$/, '')

        # Ensure Unix line endings
        content.gsub!(/\r\n?/, "\n")

        # Add final newline if missing
        content << "\n" unless content.end_with?("\n")

        if content != original_content
          File.write(file_path, content)
          return "Fixed: Whitespace issues in #{file_path}"
        end

        nil # No issues found
      rescue => e
        "Error processing #{file_path}: #{e.message}"
      end

      private

      def binary_file?(file_path)
        # Check file extension for common binary types
        binary_extensions = [
          '.png', '.jpg', '.jpeg', '.gif', '.ico', '.pdf', '.zip',
          '.tar', '.gz', '.exe', '.dll', '.so', '.dylib', '.class',
          '.jar', '.war', '.ear', '.o', '.a', '.lib'
        ]

        binary_extensions.any? { |ext| file_path.downcase.end_with?(ext) }
      end
    end
  end
end

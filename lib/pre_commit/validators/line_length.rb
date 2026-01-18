# Line length validator for mruby pre-commit framework
module PreCommit
  module Validators
    class LineLength
      def initialize(max_length = 80)
        @max_length = max_length
      end

      def validate(file_path)
        return unless File.file?(file_path)

        # Skip binary and minified files
        return if binary_file?(file_path) || minified_file?(file_path)

        violations = []
        File.readlines(file_path).each_with_index do |line, index|
          # Skip lines that are just whitespace
          next if line.strip.empty?

          # Skip comment lines that might have URLs or long paths
          next if comment_line?(line)

          if line.chomp.length > @max_length
            violations << "Line #{index + 1} exceeds #{@max_length} characters"
          end
        end

        violations.empty? ? nil : "#{file_path}: #{violations.join(', ')}"
      end

      private

      def binary_file?(file_path)
        binary_extensions = [
          '.png', '.jpg', '.jpeg', '.gif', '.ico', '.pdf', '.zip',
          '.tar', '.gz', '.exe', '.dll', '.so', '.dylib', '.class',
          '.jar', '.war', '.ear', '.o', '.a', '.lib'
        ]
        binary_extensions.any? { |ext| file_path.downcase.end_with?(ext) }
      end

      def minified_file?(file_path)
        file_path.downcase.include?('.min.') ||
          file_path.downcase.end_with?('.min.js', '.min.css')
      end

      def comment_line?(line)
        stripped = line.strip
        stripped.start_with?('#', '//', '/*', '*') ||
          stripped.include?('http://') ||
          stripped.include?('https://') ||
          stripped.include?('www.')
      end
    end
  end
end
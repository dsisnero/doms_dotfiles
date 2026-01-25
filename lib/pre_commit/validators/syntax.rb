# Syntax validator for mruby pre-commit framework
module PreCommit
  module Validators
    class Syntax
      def validate(file_path)
        return unless File.file?(file_path)

        # Only validate Ruby files for syntax
        return unless file_path.end_with?('.rb')

        begin
          content = File.read(file_path)

          # Basic syntax validation that works within mruby constraints
          validate_ruby_syntax(content)

          nil # No syntax errors found
        rescue SyntaxError => e
          "Syntax error in #{file_path}: #{e.message}"
        rescue => e
          "Error checking syntax in #{file_path}: #{e.message}"
        end
      end

      private

      def validate_ruby_syntax(code)
        # Basic syntax validation that works within mruby constraints
        # This is a lightweight check that doesn't require full parsing

        # Check for balanced brackets, braces, and parentheses
        balanced_braces = code.count('{') == code.count('}')
        balanced_brackets = code.count('[') == code.count(']')
        balanced_parens = code.count('(') == code.count(')')

        unless balanced_braces && balanced_brackets && balanced_parens
          raise SyntaxError, "Unbalanced brackets, braces, or parentheses"
        end

        # Check for unterminated strings
        check_unterminated_strings(code)

        # Check for unterminated comments
        check_unterminated_comments(code)
      end

      def check_unterminated_strings(code)
        in_single_quote = false
        in_double_quote = false
        in_heredoc = false
        escape_next = false

        code.each_char.with_index do |char, index|
          if escape_next
            escape_next = false
            next
          end

          case char
          when '\\'
            escape_next = true
          when "'"
            unless in_double_quote || in_heredoc
              in_single_quote = !in_single_quote
            end
          when '"'
            unless in_single_quote || in_heredoc
              in_double_quote = !in_double_quote
            end
          end
        end

        if in_single_quote || in_double_quote
          raise SyntaxError, "Unterminated string"
        end
      end

      def check_unterminated_comments(code)
        lines = code.lines
        in_block_comment = false

        lines.each_with_index do |line, index|
          stripped = line.strip

          if in_block_comment
            if stripped.include?('=end')
              in_block_comment = false
            end
          else
            if stripped.start_with?('=begin')
              in_block_comment = true
            end
          end
        end

        if in_block_comment
          raise SyntaxError, "Unterminated block comment"
        end
      end
    end
  end
end

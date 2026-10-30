; Vendored from cathaysia/tree-sitter-asciidoc @ 882e4317 (asciidoc_inline queries, Apache-2.0).
; Helix captures/quirks only -- see docs.helix-editor.com/themes.html#scopes before editing.

((stem_macro
  (macro_name) @_latex
  (attr) @injection.content)
  (#eq? @_latex "latexmath")
  (#set! injection.language "latex"))

((stem_macro
  (macro_name) @_asciimath
  (attr) @injection.content)
  (#any-of? @_asciimath "stem" "asciimath")
  (#set! injection.language "asciimath"))

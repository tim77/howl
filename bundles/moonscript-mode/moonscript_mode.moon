-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import formatting from howl

class MoonscriptMode
  new: =>
    @lexer = bundle_load('moonscript_lexer.moon')

  short_comment_prefix: '--'

  indent_patterns: {
    '[-=]>%s*$', -- fdecls
    '[([{:=]%s*$' -- hanging operators
    r'^\\s*\\b(class|switch|do|with|for|when)\\b', -- block starters
    { r'^\\s*\\b(elseif|if|while|unless)\\b', '%sthen%s*'}, -- conditionals
    '^%s*else%s*$',
    { '=%s*if%s', '%sthen%s*'} -- 'if' used as rvalue
  }

  dedent_patterns: {
    authoritive: false
    r'^\\s*(else|\\})\\s*$'
    { '^%s*elseif%s', '%sthen%s*' }
  }

  on_char_added: (args, editor) =>
    if args.key_name == 'return'
      return true if formatting.ensure_block editor, '{%s*$', '^%s*}', '}'

    @parent.on_char_added @, args, editor

  structure: (editor) =>
    buffer = editor.buffer
    lines = {}
    parents = {}
    prev_line = nil

    patterns = {
      '%s*class%s+%w'
      r'\\w\\s*[=:]\\s*(\\([^)]*\\))?\\s*[=-]>'
      r'(?:it|describe|context)\\(?\\s+[\'"].+->\\s*$'
    }

    for line in *editor.buffer.lines
      if prev_line
        if prev_line.indentation < line.indentation
          append parents, prev_line
        else
          parents = [l for l in *parents when l.indentation < line.indentation]

      prev_line = line

      for p in *patterns
        if line\umatch p
          for i = 1, #parents
            append lines, table.remove parents, 1

          append lines, line
          prev_line = nil
          break

    #lines > 0 and lines or self.parent.structure @, editor

return MoonscriptMode

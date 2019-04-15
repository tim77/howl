import interact from howl
import Matcher from howl.util

-- the *_searcher functions are iterators that return matched chunks, at most one per line

matcher_searcher = (buffer, lines) ->
  line_entries = [{:line, case_text: line.text, text: line.text.ulower} for line in *lines]
  (query) ->
    matcher = Matcher.create_matcher query
    idx = 0
    ->
      idx += 1
      entry = line_entries[idx]

      while entry
        how, positions = matcher entry.text, entry.case_text
        if how
          -- return a chunk for the matched segment within the line
          return buffer\chunk entry.line.start_pos + positions[1] - 1, entry.line.start_pos + positions[#positions] - 1

        idx += 1
        entry = line_entries[idx]


regex_searcher = (buffer, lines) ->
  (query) ->
    regex = r query
    idx = 0
    ->
      idx += 1
      line = lines[idx]

      while line
        start_pos, end_pos = line.text\ufind regex
        if start_pos
          -- return a chunk for the matched segment within the line
          return buffer\chunk line.start_pos + start_pos - 1, line.start_pos + end_pos - 1
        idx += 1
        line = lines[idx]

exact_searcher = (buffer, lines) ->
  (query) ->
    idx = 0
    ->
      idx += 1
      line = lines[idx]

      while line
        start_pos, end_pos = line.text\ufind query, 1, true
        if start_pos
          -- return a chunk for the matched segment within the line
          return buffer\chunk line.start_pos + start_pos - 1, line.start_pos + end_pos - 1

        idx += 1
        line = lines[idx]

interact.register
  name: 'buffer_search'
  description: 'Search buffer lines using specified strategy'
  handler: (opts={}) ->
    error 'buffer required' unless opts.buffer
    lines = if opts.lines then opts.lines else opts.buffer.lines

    -- search is an iterator that returns buffer chunks
    search = switch opts.strategy
      when 'matcher' then matcher_searcher(opts.buffer, lines)
      when 'regex' then regex_searcher(opts.buffer, lines)
      when 'exact' then exact_searcher(opts.buffer, lines)
      else
        error "invalid strategy #{opts.strategy}"

    search_view = howl.ui.SearchView
      editor: opts.editor or howl.app.editor
      buffer: opts.buffer
      prompt: opts.prompt
      title: opts.title
      preview_lines: lines
      preview_selected_line: opts.selected_line
      :search
      limit: 1000

    howl.app.window.command_panel\run search_view, text: opts.text, cancel_for_keymap: opts.cancel_for_keymap, help: opts.help

find_iterator = (buffer, start_pos, end_pos, find, parse_query) ->
  -- construct a chunk iterator from a general find(text, query, start) function
  lines = buffer.lines\for_text_range start_pos, end_pos
  (query) ->
    if parse_query
      query = parse_query query

    idx = 1
    line = lines[idx]
    search_start = if line.start_pos < start_pos then start_pos - line.start_pos + 1 else 1
    ->
      while line
        line_start = line.start_pos
        match_start, match_end, match_info = find line.text, query, search_start
        if match_start
          -- return a chunk for the matched segment
          search_start = match_end + 1
          return if line_start + match_end - 1 > end_pos  -- match beyond end_pos
          return buffer\chunk(line_start + match_start - 1, line_start + match_end - 1), match_info
        else
          idx += 1
          line = lines[idx]
          search_start = 1

interact.register
  name: 'buffer_replace'
  description: 'Generic replacement in buffer, returns updated text'
  handler: (opts={}) ->
    error 'buffer required' unless opts.buffer
    error 'find function required' unless opts.find
    error 'replace function required' unless opts.replace

    start_pos = opts.chunk and opts.chunk.start_pos or 1
    end_pos = opts.chunk and opts.chunk.end_pos or opts.buffer.length
    search = find_iterator(opts.buffer, start_pos, end_pos, opts.find, opts.parse_query)

    search_view = howl.ui.SearchView
      editor: opts.editor or howl.app.editor
      buffer: opts.buffer
      prompt: opts.prompt
      title: opts.title
      search: search
      replace: opts.replace

    howl.app.window.command_panel\run search_view, text: opts.text, cancel_for_keymap: opts.cancel_for_keymap, help: opts.help

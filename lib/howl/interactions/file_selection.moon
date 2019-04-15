-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :interact, :Project} = howl
{:DirectoryExplorer} = howl.explorers
{:File} = howl.io

interact.register
  name: 'select_file'
  description: ''
  handler: (opts={}) ->
    path = opts.path or File.home_dir.path
    explorer_path, text = DirectoryExplorer.for_path path, files_only: true, allow_new: opts.allow_new, show_subtree: opts.show_subtree
    interact.explore
      prompt: opts.prompt
      path: explorer_path
      text: text
      help: opts.help
      transform_result: (item) -> item.file

interact.register
  name: 'select_directory'
  description: ''
  handler: (opts={})->
    path = opts.path or File.home_dir.path
    interact.explore
      title: opts.title
      prompt: opts.prompt
      help: opts.help
      path: howl.explorers.DirectoryExplorer.for_path path, directories_only: true
      transform_result: (item) -> item.file

get_project = ->
  if app.editor
    file = app.editor.buffer.file or app.editor.buffer.directory
    if file
      return Project.for_file file

interact.register
  name: 'select_file_in_project'
  description: ''
  handler: (opts={}) ->
    project = opts.project or get_project!
    return unless project

    interact.explore
      prompt: opts.prompt
      title: opts.title or project.root.short_path .. ': '
      help: opts.help
      path: howl.explorers.DirectoryExplorer.for_path project.root.path,
        root: project.root,
        show_subtree: true,
        files_only: true,
        allow_new: true,
      transform_result: (item) -> item.file

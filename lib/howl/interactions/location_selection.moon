-- Copyright 2012-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:interact} = howl
{:Preview} = howl.interactions.util

local LocationExplorer, LocationItem

interact.register
  name: 'select_location'
  description: 'Selection list for locations which specify positions or chunks within files'
  handler: (opts={}) ->
    interact.explore
      title: opts.title
      prompt: opts.prompt
      text: opts.text
      path: {LocationExplorer opts.items, opts.selection, opts.columns}
      transform_result: (location_item) -> location_item.location

class LocationExplorer
  new: (@locations, @selected_item, @columns) =>
    error 'locations required' unless @locations
    @previewer = Preview!

  display_path: => ''

  display_columns: => @columns

  display_items: =>
    [LocationItem(location, @previewer) for location in *@locations], @selected_item

class LocationItem
  new: (@location, @previewer) =>
    line_nr = @location.line_nr or 1
    if @location.buffer
      if @location.pos  -- pos only works with buffer atm
        pos = @location.pos
        @chunk = @location.buffer\chunk pos, pos
      else
        line = @location.buffer.lines[line_nr]
        if line
          @chunk = line.chunk
    elseif @location.file
      buffer = self.previewer\get_buffer @location.file, line_nr or 1
      line = buffer.lines[line_nr]
      if line
        @chunk = line.chunk
    elseif @location.chunk
      @chunk = @location.chunk
    else
      error 'location.buffer or location.file or location.chunk required'

  display_row: => @location

  preview: =>
    if @chunk
      return chunk: @chunk, popup: @location.popup
    else
      return text: 'Preview not available'

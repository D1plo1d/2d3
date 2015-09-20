React = require "react"
{div} = React.DOM
Keybinding = require "react-keybinding"
SketchComponent = React.createFactory require "./sketch.js"

Sketch = require("../kernel/sketch.coffee")

# This will eventually be the place that we put multiple sketches.
# It will also have a project "model" in the kernel.
module.exports = ProjectComponent = React.createClass
  displayName: "ProjectComponent"

  mixins: [
    Keybinding
  ]

  keybindingsPlatformAgnostic: true
  keybindings:
    "⌘N": (e) -> @newSketch()

  getInitialState: ->
    sketch: new Sketch()

  # componentWillMount: ->
  #   @newSketch()

  newSketch: (e) ->
    setState sketch: new Sketch()
    @props.project.add @state.sketch
    e?.stopPropagation()
    e?.preventDefault()
    return false

  render: ->
    SketchComponent
      sketch: @state.sketch

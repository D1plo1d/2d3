React = require "react"
{path} = React.DOM
interact = require "interact.js"
cx = require "classnames"

Point = require("../kernel/point")

# Renders a single point as a SVG path
#
# Required props:
# - kernelElement
# - bringToTop
# - toKernelPx
module.exports = PointComponent = React.createClass
  displayName: "PointComponent"

  getInitialState: ->
    selected: false
    visible: false

  componentWillMount: ->
    # Hiding the dom element until we establish the mouse position for placement
    @setState visible: @props.kernelElement.placed
    # Binding events
    @props.kernelElement.on "move", @forceUpdate

  componentDidMount: ->
    domNode = React.findDOMNode @refs.point
    @_draggable = interact(domNode)
      .origin('self')
      .draggable
      .on("dragstart", @_onDragStart)
      .on("dragmove", @_onDrag)
      .on("dragend", @_onDragEnd)

    @_startPlacement() unless @props.kernelElement.placed

  _startPlacement: ->
    @setState dragStartKernelPosition: [0, 0]
    @_draggable
      .on "dragmove", @_onPlacementMove
      .on "dragend", @_onPlacementEnd
      .fire "dragstart"

  _onPlacementMove = ->
    @setState visible: true
    @_draggable.off @_onPlacementMove

  _onPlacementEnd = ->
    @props.kernelElement.place()
    @_draggable.off @_onPlacementEnd

  _onDragStart: =>
    @setState
      selected: true
      # Saving the current kernel element position for use in _onDrag
      dragStartKernelPosition: ["x", "y"].map (k) -> @props.kernelElement[k]
    @props.bringToTop()

  _onDrag: (e) =>
    e.stopPropagation()
    # Calculating the new position of the point in kernel pixels
    # (the kernel's zoom-independent unit of distance)
    position = _.map ["dx", "dy"], (k, i) ->
      @props.toKernelPx(e[k]) + @state.dragStartKernelPosition[i]
    # Calculating the snap distance in kernel pixels
    snapDistance = @props.toKernelPx Point.snapDistance
    # Moving the kernel object. It will then emit a move event after it runs the
    # constraint solver on the new data.
    @props.kernelElement.move position..., true, snapDistance

  _onDragEnd: =>
    @props.kernelElement.mergeCoincidentPoints()
    @setState selected: false

  render: ->
    path
      ref: "point"
      className: cx "implicit-point",
        "data-selected": @state.selected
      d: "M0,0L0,0"
      x: @props.kernelElement.x
      y: @props.kernelElement.y
      visibility: @state.visible

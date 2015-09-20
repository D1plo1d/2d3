React = require "react"
{div, svg, g, ul, li} = React.DOM
_ = require "lodash"
Mousetrap = require "mousetrap"
config = require "../config.coffee"

Shape = require("../kernel/shape.coffee")
Point = require("../kernel/point.coffee")

module.exports = class SketchComponent extends React.Component
  displayName: "SketchComponent"

  state:
    enabled: true
    zoomLevel: 1

  _shapeKeys: ["line"]

  componentWillMount: ->
    @_sketchWillChange @props.sketch
    @_updateKeyboardEvents()

  componentWillReceiveProps: (nextProps) ->
    @_sketchWillChange nextProps.sketch if nextProps.sketch != @props.sketch

  componentWillUpdate: (nextProps, nextState) ->
    if nextState.enabled != @state.enabled
      @_updateKeyboardEvents nextState.enabled

  incrementZoom: (increment = 0.1) ->
    @setState zoomLevel: @state.zoomLevel + increment

  bringToFront: (point) ->
  #   # Re-order the points array so that the brought-to-the-front point is the
  #   # first.
  #   points = _.remove @state.points, point
  #   points.concat [point]
  #   @setState points: points

  toKernelPx: (px) =>
    px / @state.zoomLevel

  _sketchWillChange: (newSketch) ->
    # Resetting the list of guides
    @setState {guides: []}
    newSketch.on "add", @_onAdd
    @test()

  _onAdd: =>
    @forceUpdate()

  _updateKeyboardEvents: (enable = @state.enabled) ->
    bind_or_unbind = if enable then "bind" else "unbind"
    @_keyboardEvents ||= [
      # Delete and Cancel
      ["del", @props.sketch.deleteSelection, "keyup"]
      ["esc", @props.sketch.cancel,          "keyup"]
      # Zoom
      ["+", _.partial @incrementZoom, +0.1]
      ["-", _.partial @incrementZoom,  -0.1]
    ]
    Mousetrap[bind_or_unbind](args...) for args in @_keyboardEvents

  _addPoint: (e) =>
    @props.sketch.add new Point()
    e?.stopPropagation()

  _addShape: (type, e) =>
    @props.sketch.add new Shape(type: type)
    e?.stopPropagation()

  test: ->
    p = new Point()
    p.x = 10
    p.y = 10
    # p.placed = true
    # @props.sketch.add p
    @props.sketch.add new Shape(type: "line")

  _svgStyles: ->
    strokeDasharray: "100%"
    strokeWidth: "100%"

  _scaledGroup: (k) ->
    components = @props.sketch[k].map (shape) =>
      config.shapeFactories()[shape.type]
        key: shape.id
        kernelElement: shape
        bringToFront: @bringToFront
        toKernelPx: @toKernelPx
        sketch: @props.sketch
    attrs =
      key: "#{k}Group"
      scaleX: @state.zoomLevel
      scaleY: @state.zoomLevel
    g attrs, components

  render: ->
    div {},
      # Sketch
      div className: "sketch-body",
        svg style: @_svgStyles(),
          # Text
          g key: "textGroup"
          # Points
          @_scaledGroup "points"
          # Guides
          # @_scaledGroup "guides"
          # Other shapes
          @_scaledGroup "shapes"
      # Tool Selection Menu
      div className: "sketch-menu",
        div className: "hub",
          ul {},
            @_shapeKeys.map (k) =>
              li
                className: "btn-#{k} #{k}",
                onClick: _.partial(@_addShape, k),
                key: k,
                k
            li
              className: "btn-point point",
              onClick: @_addPoint,
              key: "point",
              "point"

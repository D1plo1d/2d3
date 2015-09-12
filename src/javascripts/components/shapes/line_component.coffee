React = require "react"
{div} = React.DOM

Shape = require("../../kernel/shape.coffee")

module.exports = LineComponent = React.createClass
  displayName: "LineComponent"

  mixins: [ShapeMixin]

  initialNumberOfPoints: 2
  svgType: "path"
  shapeType: "line"

  create: (fullyDefined) ->
    @addNthPoint @kernelElement.points.length unless @state.fullyDefined

  attrs: ->
    d: @_path()

  _path: ->
    p = @kernelElement.points
    "M#{p[0].x}, #{p[0].y}L#{p[1].x},#{p[1].y}"

  _onFullyDefine: =>
    return unless @parent.shift
    @sketch.add new Shape
      type: @shapeType
      points: [@kernelElement.points[1]]

React = require "react"
{div} = React.DOM

Point = require("../kernel/point")

# The shared mixin for all shapes
#
# Required props:
# - kernelElement
# - sketch
# - bringToTop
# - toKernelPx
#
# Requires the following to be defined by the component:
# - initialNumberOfPoints [Number]
# - svgType [String]
# - shapeType [String]
# - create(fullyDefined [Boolean])
# - initSvgElement()
# - attrs()
#
# Optional:
# - onFullyDefine()
module.exports = ShapeMixin =
  # These variables must be overriden by classes this is mixed into
  initialNumberOfPoints: undefined
  svgType: undefined
  shapeType: undefined

  getInitialState: ->
    guides: []
    numberOfPoints: @initialNumberOfPoints
    visible: false

  componentWillMount: ->
    @kernelElement
      .on("fullyDefine", @onFullyDefine)
      .on("addPoint", @_onAddPoint)
      .on("removePoint", @_onRemovePoint)

    @setState fullyDefined: @kernelElement.isFullyDefined()

    @_onAddPoint p for p in @kernelElement.points

    # call the shape's create method with the ui flag for shape-specific
    # intialization
    @create()

  addNthPoint: (n) ->
    point = new Point()
    @props.sketch.add point
    @kernelElement.add point
    point.on "place", @addNthPoint.fill(n+1)

  _onAddPoint: (point) ->
    point.on "move", @_onPointMove
    # if this shape is selected style the newly added point appropriately
    @props.sketch.updateSelection()

  _onFullyDefine: ->
    @setState fullyDefined: true
    @onFullyDefine?()

  _onRemovePoint: (point) ->
    point.off "move", @_onPointMove

  _onPointMove: ->
    @forceUpdate()

  # # adds and and initializes a guide (a graphical element for shape
  # # constructing purposes) to this shape
  # _addGuide: (guideElement) ->
  #   @guides.push guideElement
  #   return guideElement

  render: ->
    attrs = _.merge @attrs(), visible: @state.visible
    React.DOM[@svgType] attrs

  # gets updated svg attributes as a hash.
  # The attributes should be in the order as they are passed to the elements constructor.
  # _attrs: -> throw "you need to overwride the _attrs function for your shape!"

  # sets this shapes element to a new element with given attributes
  # (optional) and initializes its event listeners and properties
  # _initSvgElement: (attrs) ->
  #   return if @_svgElementInitialized == true
  #   @_svgElementInitialized = true
  #   # if no element exists, use the provide options or the _attr() method to generate attributes
  #   # for a new element
  #   # unless @element?
  #   #   attrs = @_attrs() unless attrs?
  #   #   @element = @props.sketch.paper[@raphaelType].apply( @props.sketch.paper, _.values( attrs ) )

  #   # move the shape behind the points
  #   @svgElement.toBack()

  #   # store the $node variable for the element
  #   @$node = $(@svgElement.node)
  #   if @svgType == "text" and this.shapeType == "point"
  #     @$node = $(@$node).find("tspan")
  #   @$node.addClass(this.shapeType)

  #   # if this shape is selected style it appropriately
  #   @props.sketch.updateSelection()

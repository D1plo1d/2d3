SketchElement = require "./sketch_element.coffee"
# _ = require "lodash"

module.exports = class Shape extends SketchElement
  points: null
  guides: null
  visibleGuides: false
  initialized: false
  # Treat these as read only after instantiation
  type: null

  constructor: ->
    @points = []
    @guides = []
    super
    @on "addPoint", @_onAddPoint
    @on "removePoint", @_onRemovePoint
    @on "unselect", @_onUnselect
    @on "delete", @_onDelete
    # setup each predefined point
    @add p, true for p in @points

  add: (p, eventsOnly = false) ->
    @emit "beforeAddPoint", p
    @points.push p unless eventsOnly
    @emit "fullyDefine" if @isFullyDefined()
    @emit "addPoint", p

  showGuides: (value = true) ->
    @_updateAttr "visibleGuides", value, false: "hideGuides", true: "showGuides"

  _onDelete: (currentTarget, originalTarget) =>
    point.delete(originalTarget) for point in @points

  # True if the shape has all it's points defined
  isFullyDefined: ->
    return true if @_previouslyFullyDefined
    hasEnoughPoints = @points.length == @requiredPointCount()
    @_previouslyFullyDefined = hasEnoughPoints and _.last(@points)?.placed

  requiredPointCount: ->
    switch @type
      when "line" then 2
      when "circle" then 1

  cancel: =>
    @delete(@) unless @isFullyDefined()

  # cancels the current operation on this shape (if any)
  _onUnselect: =>
    @delete() unless @isFullyDefined()

  _onAddPoint: (point) =>
    @_togglePointEvents point, "on"

  _onRemovePoint: (point) =>
    @_togglePointEvents point, "off"

  _togglePointEvents: (point, toggle) ->
    # point deletion -> deletes this shape as well
    point[toggle]("beforeDelete", @_onBeforePointDelete)
    # point merging -> switch over to the new point
    point[toggle]("merge", @_onPointMerge)
    point[toggle]("place", @_onPointPlace)

  _onPointPlace: =>
    @emit "fullyDefine" if !@_previouslyFullyDefined and @isFullyDefined()

  _onPointMerge: (point, e) =>
    return unless point == e.deadPoint
    @points[@points.indexOf(e.deadPoint)] = e.mergedPoint
    @emit "removePoint", e.deadPoint
    @emit "addPoint", e.mergedPoint

  _onBeforePointDelete: (point, originalTarget) =>
    return @delete() if @_deleting or @points.include originalTarget
    # if the original target of deletion is a unrelated shape containing a
    # shared point then prevent the shared point from being deleted. It is
    # still required by this shape.
    point.preventDeletion()

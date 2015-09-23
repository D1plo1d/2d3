SketchElement = require "./sketch_element.coffee"
Vector = require "./vector.js"

module.exports = class Point extends SketchElement
  x: 0, y: 0
  initialized: false
  placed: false
  hidden: false
  snappable: true
  # Default snapping distance for all points
  @snapDistance = 10
  type: "point"

  place: () ->
    @placed = true
    @emit "place"

  drag: () ->
    @emit "dragStart"

  # Moves this point. If input is set to true (default) this move will be
  # treated as input to the constraint solver and the constraints will
  # orient themselves to anchor the point at the given position.
  # If anchor is set to false this is a constraint solver generated movement.
  move: (@x, @y, input = true, snapDistance = Point.snapDistance) ->
    @initialized = true
    @_snapToNearestPoint snapDistance if input and @sketch? and @snappable
    @emit "move"
    return if input
    @emit "diff", type: "change", x: @x, y: @y

  distanceTo: Vector.prototype.distanceTo
  subtract: Vector.prototype.subtract

  # Sets the vectors elements to those of the nearest point within snapping
  # distance or leaves them unchanged if there is no point close enough to
  # snap to.
  #
  # return: the nearest snappable point or null if no point is close enough
  # to snap to.
  _snapToNearestPoint: (snapDistance) ->
    @_coincidentPoint = null
    nearestDistance = Number.MAX_VALUE

    for p2 in @sketch.points
      # check that the other point is not this point
      continue if @ == p2 or p2.isDeleted() or !p2.snappable

      # check if the other point is within snapping distance of this point and
      # it is the nearest point
      distance = @distanceTo(p2)
      continue unless distance <= snapDistance and distance < nearestDistance

      nearestDistance = distance
      @_coincidentPoint = p2

    # if a nearby snappable point was discovered, snap to it and record it
    return unless @_coincidentPoint?
    @[k] = @_coincidentPoint[k] for k in ['x', 'y']

  mergeCoincidentPoints: ->
    @merge(@_coincidentPoint) if @_coincidentPoint?
    @coincidentPoint = null

  merge: (p2) ->
    return if p2.isDeleted() or @isDeleted()
    for point in [@, p2]
      point.emit "merge", point, deadPoint: p2, mergedPoint: @
    p2.delete()

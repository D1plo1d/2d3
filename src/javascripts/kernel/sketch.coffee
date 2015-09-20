EventEmitter = require("eventemitter3")
Shape = require("./shape.coffee")
Point = require("./point.coffee")
Constraint = {} #require("") # TODO: constraints

module.exports = class Sketch extends EventEmitter
  # All the points in the sketch
  points: null
  # All the shapes in the sketch
  shapes: null
  # All the constraints in the sketch
  constraints: null
  # The currently selected points, shapes and constraints
  selected: null
  # The diff of inputs made since the previous constraint solver update
  _diffs: null

  constructor: (string) ->
    @[a] = [] for a in ['points', 'shapes', 'constraints', 'selected', '_diffs']
    deserialize(string) if string?

  add: (obj) ->
    type = switch obj.constructor
      when Shape then "shape"
      when Point then "point"
      when Constraint then "constraint"
    @["#{type}s"].push obj
    obj.sketch = @
    @_addDiffListener(type, obj) if type != "shape"
    obj.on "delete", @_onObjDelete.bind @, type
    @emit "add", obj, type

  _addDiffListener: (type, obj) ->
    id = @["#{type}s"].indexOf(obj)
    fn = _.partial @_onDiff, id: id, objectType: type
    obj.on "diff", fn

  _onDiff: (objInfo, diff) =>
    @_diffs.push _.merge {}, objInfo, diff

  _onObjDelete: (type, obj) =>
    _.remove @["#{type}s"], obj
    @emit "delete", obj, type

  select: (shape) ->
    # if the element is included in the selected shapes then
    # maintain the current selection
    return true if _.includes @selected, shape
    # prevent selection if the current shape creation is not complete
    return false if !@selected.all created: false
    # kill the previous selections
    @cancel()
    # Select the new shape
    @selected = [shape]
    @updateSelection()
    return true

  hasSelection: ->
    @selected.length > 0

  updateSelection: ->
    newSelection = _.uniq @selected.concat(@_selectedChildPoints())
    s.select() unless _.includes @selected, s for s in newSelection
    @selected = newSelection

  # every point belonging to another shape in the current selection
  _selectedChildPoints: ->
    _( s.points for s in @selected ).flatten().uniq().value()

  # every shape in the current selection except points belonging to
  # another shape in the current selection
  _selectedParentShapes: ->
    @selected.subtract @_selectedChildPoints()

  cancel: =>
    s.unselect() for s in @selected
    s.cancel() for s in @_selectedParentShapes()
    @selected = []
    @updateSelection()

  deleteSelection: ->
    @cancel()
    s.delete() for s in @_selectedParentShapes()

  # Sends the changes to the kernel since the last request to the constraint
  # solver as a single, atomic change set.
  requestConstraintsUpdate: ->
    # Note: This is so that we can combine multiple inputs (such as on a
    # touch screen) and create useful results without bashing the constraint
    # solver with partial updates.

    # TODO: send the diff to the constraint solver

    # Resetting the diff
    @_diffs = []

  _receiveConstraintsUpdate: (diffs) ->
    console.log diffs

  serialize: () ->
    JSON.stringify
      meta: { version: "0.0.0 Mega-Beta" }
      shapes: ( shape.serialize() for shape in @shapes ).compact

  _deserialize: (string) ->
    JSON.parse(string)
    for i, opts of hash.shapes
      this[opts.shapeType](opts)

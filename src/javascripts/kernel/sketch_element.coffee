EventEmitter = require("eventemitter3")

module.exports = class SketchElement extends EventEmitter
  @idCounter = 0

  sketch: null
  selected: false

  constructor: (opts) ->
    # Save opts to instance variables
    @[k] = v || @[k] for k, v of opts
    # Set the auto-increment id
    @id = SketchElement.idCounter
    SketchElement.idCounter +=1
    # sub-class specific initialization
    setTimeout(@_init, 0)

  _init: ->

  select: (value = true) ->
    @_updateAttr "selected", value, false: "unselect", true: "select"

  unselect: ->
    @select false

  _updateAttr: (attr, value, eventNames) ->
    return if @[attr] == value
    @[attr] = value
    @emit eventNames[value.toString()]

  # Deletes the sketch element.
  # @originalTarget: the shape that was deleted that started this
  #                  deletion chain.
  delete: (originalTarget = @) =>
    return if @_deleting == true

    # emit a beforeDelete event and check if deletion is prevented
    @_deleting = true
    @emit "beforeDelete", @, originalTarget: originalTarget
    return unless @_deleting
    @_deleted = true

    # delete the sketch element
    @emit "delete", @, originalTarget: originalTarget
    @emit "diff", type: "delete"
    @removeEvent() # (removes all event listeners)

  cancel: ->
    return

  # Prevents this sketch element from being deleted if it was in the process of
  # being deleted.
  preventDeletion: ->
    @_deleting = false

  isDeleted: ->
    @_deleted == true
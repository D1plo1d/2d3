EventEmitter = require("eventemitter3")

module.exports = class Project extends EventEmitter
  sketches: []

  add: (sketch) ->
    @sketches.push sketch
    @emit "add", sketch

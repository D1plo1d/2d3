React = require "react"

module.exports = Config =

  # A map of all shape components is used to allow plugins to dynamically
  # add new shapes. Components will be listed in the UI according to insertion
  # order in the map.
  #
  # eg.
  #   A component could be added via:
  #   `Mechly.config.shapeComponents.set "myShape", MyShape`
  shapeComponents: {
    point: require "./components/point.js"
    line: require "./components/shapes/line.js"
  }

  # Helper method to convert shape components into factories
  shapeFactories: ->
    factories = {}
    factories[k] = React.createFactory v for k, v of Config.shapeComponents
    factories

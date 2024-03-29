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
    line: require "./components/shapes/line.js"
    circle: require "./components/shapes/circle.js"
    arc: require "./components/shapes/arc.js"
    quadraticBezier: require "./components/shapes/quadratic_bezier.js"
    cubicBezier: require "./components/shapes/cubic_bezier.js"
    point: require "./components/point.js"
  }

  # Helper method to convert shape components into factories
  shapeFactories: ->
    factories = {}
    factories[k] = React.createFactory v for k, v of Config.shapeComponents
    factories

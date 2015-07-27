#= require "../../components/es5-shim/es5-shim.min.js"
#= require "../../components/json3/lib/json3.min.js"
#= require "../../components/jquery/jquery.min.js"
#= require "../../components/sugar/release/sugar-full.min.js"
#= require "../../components/bootstrap-stylus/js/bootstrap-tooltip.js"
#= require "../../components/bootstrap-stylus/js/bootstrap-popover.js"

React = require "react"
ProjectComponent = React.createFactory require "./components/project"
Project = require "./kernel/project"

module.exports = class Mechly extends React.Component

  getDefaultProps: ->
    shapeComponents: Mechly.config.shapeFactories()
    project: new Project

  render: ->
    ProjectComponent @props

# Global configuration
_.merge Mechly, config: require "./config"

# # The CAD Kernel
# require "kernel/kernel"
# require "kernel/sketch"
# require "kernel/sketch_element"
# require "kernel/point"
# require "kernel/shape"
# require "kernel/project"

# # The Controllers
# require "controllers/sketch_controller"
# require "controllers/shape_controller"
# require "controllers/point_controller"
# require "controllers/project_controller"
# #= require_tree "controllers/shapes"

# The App
# project = new kernel.Project()
# new ProjectController(project)


React = require "react"
ProjectComponent = React.createFactory require "./components/project_component.coffee"
Project = require "./kernel/project.coffee"
config = require "./config.coffee"

module.exports = class Mechly extends React.Component

  @defaultProps =
    shapeComponents: config.shapeFactories()
    project: new Project

  render: ->
    ProjectComponent @props

# Global configuration
Object.assign Mechly, config: config

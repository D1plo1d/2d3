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

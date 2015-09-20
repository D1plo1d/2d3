React = require "react"
ProjectComponent = React.createFactory require "./components/project_component.coffee"
Project = require "./kernel/project.coffee"
# Initialize the global mouse move listener
require "./components/clickdrag.jsx"

module.exports = class Mechly extends React.Component

  @defaultProps =
    project: new Project

  render: ->
    ProjectComponent @props

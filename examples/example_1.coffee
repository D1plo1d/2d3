React = require("react")
Mechly = require("../src/javascripts/mechly.coffee")

document.addEventListener "DOMContentLoaded", ->
  el = document.getElementById "example-1"
  React.render React.createElement(Mechly), el
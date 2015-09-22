import React from "react"
let {div} = React.DOM
import Shape from "../../kernel/shape.coffee"
import ShapeComponent from "../shape.js"
import specialKeys from "../../higher_order_components/special_keys.js"

@specialKeys()
export default class LineComponent extends ShapeComponent {
  displayName = "LineComponent"

  svgType = "path"
  shapeType = "line"

  state = Object.assign({}, ShapeComponent.defaultState, {
    numberOfPoints: 2,
    specialKeys: {shift: false}
  })

  create() {
    if (this.props.kernelElement.isFullyDefined()) return
    this.addNthPoint(this.props.kernelElement.points.length)
  }

  attrs() {
    return {d: this._path()}
  }

  _path() {
    let p = this.props.kernelElement.points.filter((p) => p.initialized)
    return p.length == 2 ? `M${p[0].x},${p[0].y}L${p[1].x},${p[1].y}` : ""
  }

  onFullyDefine = () => {
    // Remove the special key event listeners
    this.props.disableSpecialKeys()
    // in shift mode after a line is completed start another line to draw a
    // polygon.
    if (this.props.specialKeys.shift) this._continuePolygon()
  }

  _continuePolygon() {
    let nextLine = new Shape({
      type: this.shapeType,
      points: [this.props.kernelElement.points[1]],
    })
    this.props.sketch.add(nextLine)
  }
}
let React = require("react")
let {div} = React.DOM

let Shape = require("../../kernel/shape.coffee")
let ShapeComponent = require("../shape.js")

export default class LineComponent extends ShapeComponent {
  displayName = "LineComponent"

  svgType = "path"
  shapeType = "line"

  state = Object.assign({}, ShapeComponent.defaultState, {
    numberOfPoints: 2,
  })

  create() {
    if (this.props.kernelElement.isFullyDefined()) return
    this.addNthPoint(this.props.kernelElement.points.length)
  }

  attrs() {
    return {d: this._path()}
  }

  _path() {
    let p = this.props.kernelElement.points
    return p.length == 2 ? `M${p[0].x},${p[0].y}L${p[1].x},${p[1].y}` : ""
  }

  // TODO: polygons
  // onFullyDefine() {
  //   if (!this.parent.shift) return
  //   // in shift mode after a line is completed start another line to draw a
  //   // polygon.
  //   this.sketch.add(new Shape({
  //     type: this.shapeType,
  //     points: [this.props.kernelElement.points[1]],
  //   }))
  // }
}
import React from "react"
let {div} = React.DOM
import CSSModules from "react-css-modules"
import styles from "../../../stylesheets/components/shapes/line.styl"
import Shape from "../../kernel/shape.coffee"
import ShapeComponent from "../shape.js"
import specialKeys from "../../higher_order_components/special_keys.js"

@specialKeys()
@CSSModules(styles)
export default class LineComponent extends ShapeComponent {
  displayName = "LineComponent"

  svgType = "path"
  shapeType = "line"

  state = Object.assign({}, ShapeComponent.defaultState, {
  })

  attrs() {
    return {
      // styleName: "line",
      d: this._path(),
    }
  }

  _path() {
    let p = this.points()
    return `M${p[0].x},${p[0].y}L${p[1].x},${p[1].y}`
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
      points: [this.points()[1]],
    })
    this.props.sketch.add(nextLine)
  }

}
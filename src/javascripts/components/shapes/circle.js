import React from "react"
let {div} = React.DOM
import CSSModules from "react-css-modules"
import styles from "../../../stylesheets/components/shapes/circle.styl"
import ShapeComponent from "../shape.js"

@CSSModules(styles)
export default class LineComponent extends ShapeComponent {
  displayName = "CircleComponent"

  svgType = "ellipse"
  shapeType = "circle"

  defaultProps = {
    radius: 0
  }

  state = {
    draggingShape: false
  }

  radius() {
    return this.points()[0].distanceTo(this.points()[1])
  }

  // creates the element attributes
  attrs() {
    return {
      styleName: "circle",
      cx: this.points()[0].x,
      cy: this.points()[0].y,
      rx: this.radius(),
      ry: this.radius(),
    }
  }

}

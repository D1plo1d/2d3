import React from "react"
import CSSModules from "react-css-modules"
import styles from "../../../stylesheets/components/shapes/circle.styl"
import ShapeComponent from "../shape.js"

@CSSModules(styles)
export default class LineComponent extends ShapeComponent {
  displayName = "CircleComponent"

  shapeType = "circle"

  state = Object.assign({}, ShapeComponent.defaultState)

  _radius() {
    return this.points()[0].distanceTo(this.points()[1])
  }

  onMouseDown = (e) => {
    let point = this.points()[1].drag()
  }

  beforeAddNthPoint(n, point) {
    if (n === 1) {
      point.hidden = true
      point.snappable = false
    }
  }

  // creates the element attributes
  attrs(attrs) {
    return Object.assign(attrs, {
      cx: this.points()[0].x,
      cy: this.points()[0].y,
      rx: this._radius(),
      ry: this._radius(),
      onMouseDown: this.onMouseDown
    })
  }

  render() {
    let {g, ellipse} = React.DOM
    if (!this.visible()) return g({})
    return g({},
      ellipse(this.attrs({styleName: "circle"})),
      ellipse(this.attrs({styleName: "clickable-area"})),
    )
  }

}

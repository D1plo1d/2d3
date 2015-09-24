import React from "react"
import CSSModules from "react-css-modules"
import styles from "../../../stylesheets/components/shapes/bezier.styl"
import ShapeComponent from "../shape.js"
import _ from "lodash"

@CSSModules(styles)
export default class QuadraticBezierComponent extends ShapeComponent {
  displayName = "QuadraticBezierComponent"

  shapeType = "quadraticBezier"

  state = Object.assign({}, ShapeComponent.defaultState, {
  })

  _shouldShowGuides() {
    let pointCount = this.initializedPoints().length
    // if (this.props.kernelElement.isFullyDefined()) return false
    return pointCount == 3
  }

  _bezier() {
    let p = this.initializedPoints()
    switch (p.length) {
      case 2:
        var d = `M${p[0].x},${p[0].y}L${p[1].x},${p[1].y}`
        break
      case 3:
        var d =  `M${p[0].x},${p[0].y} Q${p[2].x},${p[2].y} ${p[1].x},${p[1].y}`
        break
      default:
        return
    }
    return React.DOM.path({styleName: "bezier", d})
    // if (this.initializedPoints().length < 2) return
    // let p = this.points()
    // if
    // return React.DOM.path({
    //   styleName: "bezier",
    //   d: `M${p[0].x},${p[0].y} Q${p[2].x},${p[2].y} ${p[1].x},${p[1].y}`
    // })
  }

  // the guides for interactive element creation
  _constructionGuides() {
    if (!this._shouldShowGuides()) return []
    let {path} = React.DOM
    let p = this.initializedPoints()
    // Create a guide for each initialized point excluding the 3rd one
    let endPoints = [p[0], p[1]]
    return endPoints.map( (endPoint) => {
      return path({
        styleName: "guide",
        d: `M${endPoint.x},${endPoint.y}L${p[2].x},${p[2].y}`,
      })
    })
  }

  render() {
    return React.DOM.g({},
      ...this._constructionGuides(),
      this._bezier(),
    )
  }

}

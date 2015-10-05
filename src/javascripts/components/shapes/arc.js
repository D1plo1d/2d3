import React from "react"
import CSSModules from "react-css-modules"
import styles from "../../../stylesheets/components/shapes/arc.styl"
import ShapeComponent from "../shape.js"
import Constraint from "../../kernel/constraint.js"
import _ from "lodash"

@CSSModules(styles)
export default class ArcComponent extends ShapeComponent {
  displayName = "CircleComponent"

  shapeType = "arc"

  presentAngle = 0

  state = Object.assign({}, ShapeComponent.defaultState, {
    // direction: 1
  })

  static defaultProps = {
    constructionStyle: "centerPoint"
  }

  // TODO: Constraints
  afterAddNthPoint() {
    let p = this.points()
    console.log(this.points().length)
    if (this.points().length == 3) {
      this.constraint = this.props.sketch.add(new Constraint({
        type: "coradial",
        centerID: p[0].id,
        pointIDs: [p[1], p[2]].map(({id}) => id)
      }))
    }
  }

  // TODO: constraint
  // _afterDelete() {
  //   this.constraint.delete() if this.constraint?
  // }

  _radius() {
    let p = this.points()
    return p[0].distanceTo(p[1])
  }

  _shouldShowGuides() {
    let pointCount = this.initializedPoints().length
    if (this.props.kernelElement.isFullyDefined()) return false
    return pointCount == 2 || pointCount == 3
  }

  _centerPointArcPath() {
    let p = this.points()
    let tau = 2 * Math.PI
    // calculating the central arc angle
    let angle = []
    for (let i in [1, 2]) {
      let p_relative = p[i].subtract(p[0])
      angle[i] = Math.atan2(p_relative.y, p_relative.x)
    }
    // the minor angle is the smaller of the two possible arc lengths from p[1]
    // to p[2]
    let minorAngle = angle[2] - angle[1]
    if (minorAngle > Math.PI) minorAngle -= tau
    if (minorAngle < -Math.PI) minorAngle += tau

    if (minorAngle > 0) {
      var angleA = minorAngle
      var angleB = minorAngle - tau
    }
    else {
      var angleA = tau + minorAngle
      var angleB = minorAngle
    }

    let clockwise = (
      Math.abs(angleA - this.presentAngle) <
      Math.abs(angleB - this.presentAngle)
    )

    if (clockwise) {
      var direction = 1
      this.presentAngle = angleA
    }
    else {
      var direction = -1
      this.presentAngle = angleB
    }
    // caculating the svg A path's flags
    let sweepFlag = direction == 1 ? 1 : 0
    let largeArcFlag = minorAngle * direction > 0 ? 0 : 1
    // Creating the path string
    let path = `
      M${p[1].x}, ${p[1].y}
      A${this._radius()},${this._radius()}, 0, ${largeArcFlag}, ${sweepFlag},
      ${p[2].x}, ${p[2].y}
    `
    return path.replace("\n", " ")
  }

  _arc() {
    if (this.initializedPoints().length != 3) return
    let d
    if (this.props.constructionStyle == "centerPoint") {
      d = this._centerPointArcPath()
    }
    return React.DOM.path({styleName: "arc", d})
  }

  // the guides for interactive element creation
  _constructionGuides() {
    if (!this._shouldShowGuides()) return []
    let {circle, path} = React.DOM
    let p = this.points()
    return [
      circle({
        styleName: "circumference-guide",
        cx: p[0].x,
        cy: p[0].y,
        r: this._radius(),
      }),
      path({
        styleName: "radius-guide",
        d: `M${p[0].x},${p[0].y}L${p[1].x},${p[1].y}`,
      })
    ]
  }

  render() {
    return React.DOM.g({},
      ...this._constructionGuides(),
      this._arc(),
    )
  }

}

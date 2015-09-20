import React from "react"
let {div, svg, g, ul, li} = React.DOM
import CSSModules from "react-css-modules"
import _ from "lodash"
import Mousetrap from "mousetrap"
import config from "../config.coffee"
import styles from "../../stylesheets/components/sketch/sketch.styl"

import Shape from "../kernel/shape.coffee"
import Point from "../kernel/point.coffee"

@CSSModules(styles)
export default class SketchComponent extends React.Component {
  displayName = "SketchComponent"

  state = {
    enabled: true,
    zoomLevel: 1,
  }

  _shapeKeys = ["line"]

  componentWillMount() {
    this._sketchWillChange(this.props.sketch)
    this._updateKeyboardEvents()
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.sketch != this.props.sketch) {
      this._sketchWillChange(nextProps.sketch)
    }
  }

  componentWillUpdate(nextProps, nextState) {
    if (nextState.enabled != this.state.enabled) {
      this._updateKeyboardEvents(nextState.enabled)
    }
  }

  incrementZoom(increment = 0.1) {
    this.setState({zoomLevel: this.state.zoomLevel + increment})
  }

  bringToFront(point) {
  //   // Re-order the points array so that the brought-to-the-front point is the
  //   // first.
  //   points = _.remove this.state.points, point
  //   points.concat [point]
  //   this.setState points: points
  }

  toKernelPx = (px) => {
    return px / this.state.zoomLevel
  }

  _sketchWillChange(newSketch) {
    // Resetting the list of guides
    this.setState({guides: []})
    newSketch.on("add", this._onAdd)
    this.test()
  }

  _onAdd = () => {
    this.forceUpdate()
  }

  _updateKeyboardEvents(enable = this.state.enabled) {
    let bind_or_unbind = enable ? "bind" : "unbind"
    if (this._keyboardEvents == null) {
      this._keyboardEvents = [
        // Delete and Cancel
        ["del", this.props.sketch.deleteSelection, "keyup"],
        ["esc", this.props.sketch.cancel, "keyup"],
        // Zoom
        ["+", _.partial(this.incrementZoom, +0.1)],
        ["-", _.partial(this.incrementZoom, -0.1)],
      ]
    }
    for (let args in this._keyboardEvents) Mousetrap[bind_or_unbind](...args)
  }

  _addPoint = (e) => {
    this.props.sketch.add(new Point())
    if (e != null) e.stopPropagation()
  }

  _addShape = (type, e) => {
    this.props.sketch.add(new Shape({type}))
    if (e != null) e.stopPropagation()
  }

  test() {
    let p = new Point()
    p.x = 10
    p.y = 10
    // p.placed = true
    // this.props.sketch.add p
    this.props.sketch.add(new Shape({type: "line"}))
  }

  _scaledGroup(k) {
    let components = this.props.sketch[k].map((shape) => {
      return config.shapeFactories()[shape.type]({
        key: shape.id,
        kernelElement: shape,
        bringToFront: this.bringToFront,
        toKernelPx: this.toKernelPx,
        sketch: this.props.sketch,
      })
    })
    let attrs = {
      key: `${k}Group`,
      styleName: `${k}-group`,
      scaleX: this.state.zoomLevel,
      scaleY: this.state.zoomLevel,
    }
    return g(attrs, components)
  }

  render() {
    return div({},
      // Sketch
      div({styleName: "svg-container"},
        svg({styleName: "svg"},
          // Text
          g({key: "textGroup"}),
          // Points
          this._scaledGroup("points"),
          // Guides
          // this._scaledGroup "guides"
          // Other shapes
          this._scaledGroup("shapes"),
        ),
      ),
      // Tool Selection Menu
      div({styleName: "menu"},
        div({},
          ul({},
            this._shapeKeys.map((k) => {
              return li({
                className: `btn-${k} ${k}`,
                onClick: _.partial(this._addShape, k),
                key: k,
              }, k)
            }),
            li({
              className: "btn-point point",
              onClick: this._addPoint,
              key: "point",
            }, "point"),
          ),
        ),
      ),
    )
  }

}

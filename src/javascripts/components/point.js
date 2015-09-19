let React = require("react")
let {circle} = React.DOM
let clickDrag = require("./clickdrag.jsx")
let cx = require("classnames")

let Point = require("../kernel/point.coffee")

/* Renders a single point as a SVG path
 *
 * Required props:
 * - kernelElement
 * - bringToTop
 * - toKernelPx
 */
@clickDrag()
export default class PointComponent extends React.Component {
  displayName = "PointComponent"

  state = {
    selected: false,
    visible: false,
  }

  constructor() {
    super()
    this._onMove = this._onMove.bind(this)
  }

  componentWillMount() {
    // Hiding the dom element until we establish the mouse position for
    // placement
    this.setState({visible: this.props.kernelElement.placed})
    // Binding events
    this.props.kernelElement.on("move", this._onMove)
    // Starting the placement of the point
    if (!this.props.kernelElement.placed) this._startPlacement()
  }

  componentWillUnmount() {
    this.props.kernelElement.off("move", this._onMove)
  }

  componentWillReceiveProps(nextProps) {
    if (!nextProps.clickDrag.isMoving) {
      if (this.props.clickDrag.isMoving) this._onDragEnd()
    }
    else if (this.props.clickDrag.isMoving) {
      this._onDrag(nextProps)
    }
    else {
      this._onDragStart(nextProps)
    }
  }

  _onMove() {
    this.forceUpdate()
  }

  _startPlacement() {
    this.props.clickDrag.simulateMouseDown()
  }

  _onDragStart(nextProps) {
    console.log("DRAG START")
    this.setState({
      selected: true,
      visible: true,
    })
    this.props.bringToFront()
  }

  _onDrag(nextProps) {
    // Calculating the new position of the point in kernel pixels
    // (the kernel's zoom-independent unit of distance)
    // TODO: This should be made offset independent
    let position = _.map(["x", "y"], (k, i) =>
      this.props.toKernelPx(nextProps.clickDrag[k] - 10)
    )
    // Calculating the snap distance in kernel pixels
    let snapDistance = this.props.toKernelPx(Point.snapDistance)
    // Moving the kernel object. It will then emit a move event after it runs the
    // constraint solver on the new data.
    this.props.kernelElement.move(...position, true, snapDistance)
  }

  _onDragEnd() {
    if (!this.props.kernelElement.placed) this.props.kernelElement.place()
    this.props.kernelElement.mergeCoincidentPoints()
    this.setState({selected: false})
  }

  classNamesCx() {
    return cx("implicit-point", {
      "data-selected": this.state.selected
    })
  }

  render() {
    return circle({
      ref: "point",
      className: this.classNamesCx(),
      cx: this.props.kernelElement.x,
      cy: this.props.kernelElement.y,
      r: 5,
      visibility: this.state.visible,
    })
  }

}

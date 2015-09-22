let React = require("react")
let {div} = React.DOM

let Point = require("../kernel/point.coffee")

/* The shared mixin for all shapes
 *
 * Required props:
 * - kernelElement
 * - sketch
 * - bringToTop
 * - toKernelPx
 *
 * Requires the following to be defined by the component:
 * - initialNumberOfPoints [Number]
 * - svgType [String]
 * - shapeType [String]
 * - initSvgElement()
 * - attrs()
 *
 * Optional:
 * - onFullyDefine()
 * - create(fullyDefined [Boolean])
 * - visible()
 */
export default class ShapeComponent extends React.Component {
  // These variables must be overriden by classes this is mixed into
  // initialNumberOfPoints = undefined
  svgType = undefined
  shapeType = undefined

  static defaultState = {
    guides: [],
    numberOfPoints: undefined,
  }

  componentWillMount() {
    this.props.kernelElement
      .on("fullyDefine", this.onFullyDefine)
      .on("addPoint", this._onAddPoint)
      .on("removePoint", this._onRemovePoint)

    for (let p of this.props.kernelElement.points) this._onAddPoint(p)

    // call the shape's create method with the ui flag for shape-specific
    // intialization
    this.create()
  }

  create() {
    if (this.props.kernelElement.isFullyDefined()) return
    this.addNthPoint(this.props.kernelElement.points.length)
  }

  addNthPoint(n) {
    if (this.props.kernelElement.isFullyDefined()) return
    let point = new Point()
    this.props.sketch.add(point)
    this.props.kernelElement.add(point)
    point.on("place", this.addNthPoint.bind(this, n+1))
  }

  _onAddPoint = (point) => {
    point.on("move", this._onPointMove)
    // if this shape is selected style the newly added point appropriately
    this.props.sketch.updateSelection()
  }

  onFullyDefine() {
    /* noop */
  }

  _onRemovePoint = (point) => {
    point.off("move", this._onPointMove)
  }

  _onPointMove = () => {
    this.forceUpdate()
  }

  points() {
    return this.props.kernelElement.points
  }

  // # adds and and initializes a guide (a graphical element for shape
  // # constructing purposes) to this shape
  // _addGuide: (guideElement) ->
  //   this.guides.push guideElement
  //   return guideElement

  visible() {
    let numberOfPoints = this.props.kernelElement.requiredPointCount()
    return this.points().filter((p) => p.initialized).length == numberOfPoints
  }

  render() {
    let attrs = this.visible() ? this.attrs() : {style: {visibility: "hidden"}}
    return React.DOM[this.svgType](attrs)
  }

  // gets updated svg attributes as a hash.
  // The attributes should be in the order as they are passed to the elements constructor.
  // _attrs: -> throw "you need to overwride the _attrs function for your shape!"

  // sets this shapes element to a new element with given attributes
  // (optional) and initializes its event listeners and properties
  // _initSvgElement: (attrs) ->
  //   return if this._svgElementInitialized == true
  //   this._svgElementInitialized = true
  //   // if no element exists, use the provide options or the _attr() method to generate attributes
  //   // for a new element
  //   // unless this.element?
  //   //   attrs = this._attrs() unless attrs?
  //   //   this.element = this.props.sketch.paper[this.raphaelType].apply( this.props.sketch.paper, _.values( attrs ) )

  //   // move the shape behind the points
  //   this.svgElement.toBack()

  //   // store the $node variable for the element
  //   this.$node = $(this.svgElement.node)
  //   if this.svgType == "text" and this.shapeType == "point"
  //     this.$node = $(this.$node).find("tspan")
  //   this.$node.addClass(this.shapeType)

  //   // if this shape is selected style it appropriately
  //   this.props.sketch.updateSelection()
}
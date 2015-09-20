'use strict'

var React = require('react')
var objectAssign = require('react/lib/Object.assign')

var noop = function() {}

module.exports = function clickDrag(opts = {}) {
  return function(Component) {

    var touch = opts.touch == null ? opts.touch : true
    var resetOnSpecialKeys = opts.resetOnSpecialKeys || false
    var getSpecificEventData = opts.getSpecificEventData || function() { return {} }

    return class extends React.Component {
      state = {
        simulatedMouseDown: false,
        isMouseDown: false,
        isMoving: false,
        mouseDownX: 0,
        mouseDownY: 0,
        x: 0,
        y: 0,
        deltaX: 0,
        deltaY: 0,
        simulateMouseDown: () => this.setState({
          simulatedMouseDown: true
        }),
        simulateMouseUp: () => this._onMouseUp(),
      }

      constructor() {
        super()
        this._onMouseDown = this._onMouseDown.bind(this)
        this._onMouseUp = this._onMouseUp.bind(this)
        this._onMouseMove = this._onMouseMove.bind(this)
        this._wasUsingSpecialKeys = false
      }

      componentDidMount() {
        var node = React.findDOMNode(this)

        node.addEventListener('mousedown', this._onMouseDown)
        document.addEventListener('mousemove', this._onMouseMove)
        document.addEventListener('mouseup', this._onMouseUp)

        if(touch) {
          node.addEventListener('touchstart', this._onMouseDown)
          document.addEventListener('touchmove', this._onMouseMove)
          document.addEventListener('touchend', this._onMouseUp)
        }
      }

      componentWillUnmount() {
        var node = React.findDOMNode(this)

        node.removeEventListener('mousedown', this._onMouseDown)
        document.removeEventListener('mousemove', this._onMouseMove)
        document.removeEventListener('mouseup', this._onMouseUp)

        if(touch) {
          node.removeEventListener('touchstart', this._onMouseDown)
          document.removeEventListener('touchmove', this._onMouseMove)
          document.removeEventListener('touchend', this._onMouseUp)
        }
      }

      _setMousePosition(x, y) {
        this.setState({
          isMouseDown: true,
          isMoving: false,
          mouseDownX: x,
          mouseDownY: y,
          x: x,
          y: y,
          deltaX: 0,
          deltaY: 0,
        })
      }

      _onMouseDown(e) {
        // only left mouse button
        if(touch || e.button === 0 || this.state.simulatedMouseDown) {
          var pt = (e.changedTouches && e.changedTouches[0]) || e

          this._setMousePosition(pt.clientX, pt.clientY)

          e.stopImmediatePropagation()
        }
      }

      _onMouseUp(e) {
        if(this.state.isMouseDown || this.state.simulatedMouseDown) {
          this.setState({
            simulatedMouseDown: false,
            isMouseDown: false,
            isMoving: false,
          })

          if (e != null) e.stopImmediatePropagation()
        }
      }

      _onMouseMove(e) {
        if(this.state.isMouseDown || this.state.simulatedMouseDown) {
          var pt = (e.changedTouches && e.changedTouches[0]) || e

          var isUsingSpecialKeys = e.metaKey || e.ctrlKey || e.shiftKey || e.altKey
          if(resetOnSpecialKeys && this._wasUsingSpecialKeys !== isUsingSpecialKeys) {
            this._wasUsingSpecialKeys = isUsingSpecialKeys
            this._setMousePosition(pt.clientX, pt.clientY)
          }
          else if (this.state.simulatedMouseDown && !this.state.isMouseDown) {
            this._onMouseDown(e)
          }
          else {
            this.setState(objectAssign({
              isMoving: true,
              deltaX: pt.clientX - this.state.mouseDownX,
              deltaY: pt.clientY - this.state.mouseDownY,
              x: pt.clientX,
              y: pt.clientY,
            }, getSpecificEventData(e)))
          }

          e.stopImmediatePropagation()
        }
      }

      render() {
        return <Component {...this.props} clickDrag={this.state} />
      }
    }
  }
}

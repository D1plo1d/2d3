'use strict'

var React = require('react')
var objectAssign = require('react/lib/Object.assign')

var noop = function() {}

module.exports = function clickDrag(opts = {}) {
  return function(Component) {

    var touch = opts.touch == null ? true : opts.touch
    var resetOnSpecialKeys = opts.resetOnSpecialKeys || false
    var getSpecificEventData = opts.getSpecificEventData || () => {return {}}

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
        simulateMouseDown: () => this._simulateMouseDown(),
        simulateMouseUp: () => this._onMouseUp(),
      }

      _wasUsingSpecialKeys = false

      _domNode() {
        return React.findDOMNode(this)
      }

      componentDidMount() {
        this._toggleListeners("on", document, this._globalButtonEvents())
        this._toggleListeners("on", this._domNode(), this._localButtonEvents())
      }

      componentWillUnmount() {
        this._toggleListeners("off", document, this._globalButtonEvents())
        this._toggleListeners("off", this._domNode(), this._localButtonEvents())
      }

      _localButtonEvents() {
        let events = {mousedown: this._onMouseDown}
        if(touch) events.touchstart = this._onMouseDown
        return events
      }

      _globalButtonEvents() {
        let events = {mouseup: this._onMouseUp}
        if (touch) events.touchend = this._onMouseUp
        return events
      }

      _mouseMoveEvents() {
        let events = {mousemove: this._onMouseMove}
        if (touch) events.touchmove = this._onMouseMove
        return events
      }

      _toggleListeners(onOrOff, domElement, events) {
        let add = onOrOff === "on"
        let fnName = add ? "addEventListener" : "removeEventListener"
        for(let k in events) domElement[fnName](k, events[k])
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

      _simulateMouseDown() {
        this.setState({simulatedMouseDown: true}, () => {
          this._toggleListeners("on", document, this._mouseMoveEvents())
        })
      }

      _onMouseDown = (e) => {
        // only left mouse button
        if(touch || e.button === 0 || this.state.simulatedMouseDown) {
          var pt = (e.changedTouches && e.changedTouches[0]) || e

          this._setMousePosition(pt.clientX, pt.clientY)

          e.stopImmediatePropagation()
        }
        this._toggleListeners("on", document, this._mouseMoveEvents())
      }

      _onMouseUp = (e) => {
        if(this.state.isMouseDown || this.state.simulatedMouseDown) {
          this.setState({
            simulatedMouseDown: false,
            isMouseDown: false,
            isMoving: false,
          })

          if (e != null) e.stopImmediatePropagation()
        }
        this._toggleListeners("off", document, this._mouseMoveEvents())
      }

      _onMouseMove = (e) => {
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

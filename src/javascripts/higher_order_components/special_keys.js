var React = require('react')

let globalState = {}

let updateShift = function(e) {
  let isShift = !!e.shiftKey
  globalState.shift = isShift
}

let onFirstMouseMove = function(e) {
  updateShift(e)
  window.removeEventListener("mousemove",  onFirstMouseMove)
}

window.addEventListener("mousemove", onFirstMouseMove)

window.addEventListener("keydown", function (e) {
  updateShift(e)
})

window.addEventListener("keyup", function (e) {
  updateShift(e)
})

module.exports = function specialKeys(opts = {}) {
  return function(childComponent) {
    return class extends React.Component {

      state = {
        specialKeys: globalState,
        enabled: true,
      }

      componentWillMount() {
        window.addEventListener("keydown", this.onKeyUpOrDown)
        window.addEventListener("keyup", this.onKeyUpOrDown)
      }

      componentWillUnmount() {
        this._removeListeners()
      }

      onKeyUpOrDown = (e) => {
        this.setState({specialKeys: globalState})
      }

      disableSpecialKeys = () => {
        this._removeListeners()
        this.setState({enabled: false})
      }

      _removeListeners() {
        window.removeEventListener("keydown", this.onKeyUpOrDown)
        window.removeEventListener("keyup", this.onKeyUpOrDown)
      }

      render() {
        let childProps = Object.assign({}, this.props, {
          disableSpecialKeys: this.disableSpecialKeys,
        })
        if (this.state.enabled) {
          childProps.specialKeys = this.state.specialKeys
        }
        return React.createElement(childComponent, childProps)
      }

    }
  }
}

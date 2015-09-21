var React = require('react')

module.exports = function specialKeys(opts = {}) {
  return function(childComponent) {
    return class extends React.Component {
      state = {
        shift: false,
      }

      componentWillMount() {
        window.addEventListener("keydown", this.onKeyDown)
        window.addEventListener("keyup", this.onKeyUp)
      }

      componentWillUnmount() {
        window.removeEventListener("keydown", this.onKeyDown)
        window.removeEventListener("keydown", this.onKeyUp)
      }

      onKeyDown = (e) => {
        let isShift = !!e.shiftKey
        this.setState({shift: isShift})
      }

      onKeyUp = (e) => {
        let isShift = !!e.shiftKey
        this.setState({shift: isShift})
      }

      render() {
        let childProps = Object.assign({}, this.props, {
          specialKeys: this.state,
        })
        return React.createElement(childComponent, childProps)
      }

    }
  }
}

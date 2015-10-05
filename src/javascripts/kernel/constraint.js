let EventEmitter = require("eventemitter3")

export default class Constraint extends EventEmitter {
  static nextID = 0

  constructor(params) {
    super()
    this.params = params
    this.params.id = Constraint.nextID
    Constraint.nextID++
  }

}

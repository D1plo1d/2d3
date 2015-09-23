export default class Vector {
  x = 0
  y = 0

  constructor(x, y) {
    this.x = x
    this.y = y
  }

  distanceTo(p2) {
    return Math.sqrt( Math.pow(this.x - p2.x, 2) + Math.pow(this.y - p2.y, 2) )
  }

  subtract(p2) {
    return new Vector(this.x - p2.x, this.y - p2.y)
  }

}

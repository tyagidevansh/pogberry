class Point {
  init(x, y) {
    this.x = x;
    this.y = y;
  }
  move(dx, dy) {
    this.x = this.x + dx;
    this.y = this.y + dy;
  }
  sum() {
    return this.x + this.y;
  }
}
var point = Point(2, 3);
print(point.sum());
point.move(4, -1);
print(point.x);
print(point.y);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|5
//|6
//|2
// END EXPECTED OUTPUT

let name = "Pogberry";
var scores = [3, 1, 2];
scores.sort();
var player = {"name": name, "scores": scores};
fun total(values) {
  var result = 0;
  for (var i = 0; i < len(values); i = i + 1) {
    result = result + values[i];
  }
  return result;
}
class Player {
  init(data) {
    this.data = data;
  }
  summary() {
    return this.data["name"] + ": " + str(total(this.data["scores"]));
  }
}
print(Player(player).summary());
print(player);
print(type(player));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|Pogberry: 6
//|{name: Pogberry, scores: [1, 2, 3]}
//|map
// END EXPECTED OUTPUT

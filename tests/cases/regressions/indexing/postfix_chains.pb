fun matrix() {
  return [[1, 2], [3, 4]];
}
var world = {"players": [{"name": "Ada"}, {"name": "Lin"}]};
print([10, 20][1]);
print(matrix()[1][0]);
print(world["players"][1]["name"]);
world["players"][0]["name"] = "Grace";
print(world);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|20
//|3
//|Lin
//|{players: [{name: Grace}, {name: Lin}]}
// END EXPECTED OUTPUT

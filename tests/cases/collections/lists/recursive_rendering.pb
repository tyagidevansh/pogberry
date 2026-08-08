var list = [];
list.push(list);
print(list);

var map = {};
map["self"] = map;
print(map);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|[<cycle>]
//|{self: <cycle>}
// END EXPECTED OUTPUT

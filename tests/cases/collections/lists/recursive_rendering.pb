let list = [];
list.push(list);
print(list);

let map = {};
map["self"] = map;
print(map);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|[<cycle>]
//|{self: <cycle>}
// END EXPECTED OUTPUT

use "std.json" as json;

let save = json.parse('{"name": "Mira", "health": 85, "pos": [10, -2.5], "alive": true, "title": null}');
print(save["name"]);
print(save["health"]);
print(save["pos"]);
print(save["pos"][0]);
print(save["alive"]);
print(save["title"]);
print(json.parse("[1, [2, [3]]]"));
print(json.parse("\"hi\\nthere\""));
print(json.parse("  42  "));
print(json.parse("{}"));
print(json.parse("[]"));
print(json.parse("oops"));
print(json.parse(""));
print(json.parse("[1,]"));
print(json.parse("{\"a\": 1} trailing"));
print(json.parse("{\"a\": }"));
print(json.parse("{\"a\": \"b}"));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|Mira
//|85
//|[10, -2.5]
//|10
//|true
//|nil
//|[1, [2, [3]]]
//|hi
//|there
//|42
//|{}
//|[]
//|nil
//|nil
//|nil
//|nil
//|nil
//|nil
// END EXPECTED OUTPUT

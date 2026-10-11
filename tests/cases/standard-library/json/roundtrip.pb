use "std.json" as json;

let original = {"name": "Mi\"ra", "health": 85, "pos": [10, -2.5], "tags": ["a", "b"], "ok": true, "x": nil};
let text = json.stringify(original);
print(text);
let back = json.parse(text);
print(back["name"]);
print(back["health"]);
print(back["pos"][1]);
print(back["tags"][0]);
print(back["ok"]);
print(back["x"]);
print(back["missing"]);
print(json.stringify({1: "x"}));
fun f() {}
print(json.stringify([f]));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|{"name":"Mi\"ra","health":85,"pos":[10,-2.5],"tags":["a","b"],"ok":true,"x":null}
//|Mi"ra
//|85
//|-2.5
//|a
//|true
//|nil
//|nil
//|nil
//|nil
// END EXPECTED OUTPUT

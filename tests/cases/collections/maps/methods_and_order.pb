var data = {"a": 1, "b": 2};
print(data.has("a"));
print(data.has("missing"));
print(data.get("a", 99));
print(data.get("missing", 99));
print(data.delete("a"));
print(data.delete("a"));
data["a"] = 3;
print(data);
print(len(data));
data.clear();
print(data);
print(data.length);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|false
//|1
//|99
//|true
//|false
//|{b: 2, a: 3}
//|2
//|{}
//|0
// END EXPECTED OUTPUT

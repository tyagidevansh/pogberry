use "std.json" as json;

print(json.stringify(nil));
print(json.stringify(true));
print(json.stringify(false));
print(json.stringify(85));
print(json.stringify(-12.5));
print(json.stringify("hi"));
print(json.stringify("say \"hi\"\nbye\\"));
print(json.stringify([]));
print(json.stringify([1, "two", nil, true]));
print(json.stringify({}));
print(json.stringify({"b": 2, "a": 1}));
print(json.stringify({"pos": [10, -2.5], "alive": true, "title": nil}));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|null
//|true
//|false
//|85
//|-12.5
//|"hi"
//|"say \"hi\"\nbye\\"
//|[]
//|[1,"two",null,true]
//|{}
//|{"b":2,"a":1}
//|{"pos":[10,-2.5],"alive":true,"title":null}
// END EXPECTED OUTPUT

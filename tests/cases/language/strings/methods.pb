print("a,b,c".split(","));
print("a,,b".split(","));
print("abc".split(","));
print("".split(","));
print("one::two".split("::"));
print("health=85".find("="));
print("health=85".find("x"));
print("abc".find(""));
print("name=Mira".substr(0, 4));
print("name=Mira".substr(5));
print("name=Mira".substr(9, 10));
print("  hi \n".trim());
print("  hi \n".trim() == "hi");
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|[a, b, c]
//|[a, , b]
//|[abc]
//|[]
//|[one, two]
//|6
//|-1
//|0
//|name
//|Mira
//|
//|hi
//|true
// END EXPECTED OUTPUT

print(!nil);
print(!false);
print(!0);
print(true and "right");
print(false and "unreached");
print(nil or "fallback");
print("left" or "unreached");
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|true
//|false
//|right
//|false
//|fallback
//|left
// END EXPECTED OUTPUT

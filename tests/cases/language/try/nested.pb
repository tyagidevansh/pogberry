try {
  try {
    nope();
  } catch (inner) {
    print(inner["message"]);
  }
  print("inner done");
  nope();
} catch (outer) {
  print(outer["message"]);
}
print("outer done");
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|Undefined variable 'nope'.
//|inner done
//|Undefined variable 'nope'.
//|outer done
// END EXPECTED OUTPUT

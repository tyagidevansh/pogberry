fun f() {
  try {
    return 1;
  } finally {
    print("fin");
  }
}
print(f());

fun g() {
  try {
    return 1;
  } catch (e) {
    return 99;
  } finally {
    print("gfin");
  }
}
print(g());

fun h() {
  try {
    return 1;
  } finally {
    return 2;
  }
}
print(h());

fun k() {
  try {
    throw "orig";
  } finally {
    throw "replacement";
  }
}

try {
  k();
} catch (e) {
  print(e["value"]);
}
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|fin
//|1
//|gfin
//|1
//|2
//|replacement
// END EXPECTED OUTPUT

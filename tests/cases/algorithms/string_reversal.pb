fun reverse(value) {
  var result = "";
  for (var i = len(value) - 1; i >= 0; i = i - 1) {
    result = result + value[i];
  }
  return result;
}
print(reverse("pogberry"));
print(reverse(""));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|yrrebgop
//|
// END EXPECTED OUTPUT

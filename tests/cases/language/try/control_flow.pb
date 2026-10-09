fun withReturn(shouldThrow) {
  try {
    if (shouldThrow) throw "early";
    return "normal";
  } catch (e) {
    return "from catch";
  }
}

print(withReturn(false));
print(withReturn(true));

let total = 0;
for (let i = 0; i < 5; i += 1) {
  try {
    if (i == 2) throw i;
    if (i == 4) break;
    total = total + 10;
  } catch (e) {
    total = total + e["value"];
  }
}
print(total);

total = 0;
let i = 0;
while (i < 10) {
  i = i + 1;
  try {
    if (i % 2 == 0) continue;
    total = total + i;
  } catch (e) {
    total = total + 100;
  }
}
print(total);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|normal
//|from catch
//|32
//|25
// END EXPECTED OUTPUT

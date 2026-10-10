let t1 = 0;
for (let i = 0; i < 5; i += 1) {
  try {
    if (i == 2) break;
    t1 = t1 + 10;
  } finally {
    t1 = t1 + 1;
  }
}

let t2 = 0;
let i = 0;
while (i < 10) {
  i = i + 1;
  try {
    if (i % 2 == 0) continue;
    t2 = t2 + i;
  } finally {
    t2 = t2 + 100;
  }
}

let t3 = 0;
for (let j = 0; j < 3; j += 1) {
  try {
    if (j == 1) throw j;
    t3 = t3 + 1;
  } catch (e) {
    t3 = t3 + 1000;
    break;
  } finally {
    t3 = t3 + 10000;
  }
}

try {
  throw "stop";
} catch (e) {
  print(t1);
  print(t2);
  print(t3);
  print(e["value"]);
}
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|23
//|1025
//|21001
//|stop
// END EXPECTED OUTPUT

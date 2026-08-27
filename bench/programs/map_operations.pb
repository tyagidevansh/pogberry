let m = {};
for (var i = 0; i < 50000; i = i + 1) {
  m[str(i)] = i;
}

for (var i = 0; i < 50000; i = i + 1) {
  var exists = m.has(str(i));
}

for (var i = 0; i < 25000; i = i + 1) {
  m.delete(str(i));
}

var sum = 0;
for (var i = 25000; i < 50000; i = i + 1) {
  sum = sum + m[str(i)];
}

print(sum + m.length);

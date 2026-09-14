let m = {};
for (let i = 0; i < 50000; i = i + 1) {
  m[str(i)] = i;
}

for (let i = 0; i < 50000; i = i + 1) {
  let exists = m.has(str(i));
}

for (let i = 0; i < 25000; i = i + 1) {
  m.delete(str(i));
}

let sum = 0;
for (let i = 25000; i < 50000; i = i + 1) {
  sum = sum + m[str(i)];
}

print(sum + m.length);

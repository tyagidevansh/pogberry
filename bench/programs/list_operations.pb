let a = [];
for (var i = 0; i < 50000; i = i + 1) {
  a.push(i);
}

let sum1 = 0;
for (var i = 0; i < len(a); i = i + 1) {
  sum1 = sum1 + a[i];
}

for (var i = 0; i < 25000; i = i + 1) {
  a.pop();
}

let sum2 = 0;
for (var i = 0; i < len(a); i = i + 1) {
  sum2 = sum2 + a[i];
}

print(sum1);
print(sum2);

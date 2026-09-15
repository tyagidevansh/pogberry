let sum = 0;
for (let i = 0; i < 200; i = i + 1) {
  for (let j = 0; j < 200; j = j + 1) {
    for (let k = 0; k < 250; k = k + 1) {
      sum = sum + i * j + k;
    }
  }
}

print(sum);

var s = "";
for (var i = 0; i < 50000; i = i + 1) {
  s = s + str(i % 10);
}

print(len(s));

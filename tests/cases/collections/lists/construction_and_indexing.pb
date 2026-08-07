var values = [10, 20, 30];
print(values);
print(values[0]);
print(values[-1]);
values[1] = 25;
values[-1] = 35;
print(values);
print(len([]));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|[10, 20, 30]
//|10
//|30
//|[10, 25, 35]
//|0
// END EXPECTED OUTPUT

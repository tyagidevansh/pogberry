var values = [1, 2];
values.push(3);
values.extend([4, 5]);
values.insert(0, 0);
values.insert(-1, 3.5);
values.insert(100, 6);
print(values);
print(values.pop());
print(values.pop(1));
values.remove(3.5);
print(values.removeAt(-1));
print(values);
values.clear();
print(values);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|[0, 1, 2, 3, 4, 3.5, 5, 6]
//|6
//|1
//|5
//|[0, 2, 3, 4]
//|[]
// END EXPECTED OUTPUT

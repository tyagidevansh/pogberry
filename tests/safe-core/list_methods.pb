var items = [1, 2];
items.extend([2, 3]);
print(items);
print(items.index(2));
print(items.count(2));

var copy = items.copy();
copy.reverse();
print(copy);

print(items.removeAt(1));
print(items);
items.clear();
print(items);

var sortable = [3, 1, 2];
sortable.sort();
print(sortable);

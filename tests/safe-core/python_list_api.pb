var items = [10, 20];
items.append(30);
print(items[-1]);

items.insert(-1, 15);
print(items);

items.remove(15);
print(items.pop());
print(items)
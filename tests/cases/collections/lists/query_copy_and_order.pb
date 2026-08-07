var values = [3, 1, 2, 1];
print(values.index(1));
print(values.count(1));
var copy = values.copy();
copy.reverse();
print(copy);
print(values);
values.sort();
print(values);
var words = ["pear", "apple", "banana"];
words.sort();
print(words);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|1
//|2
//|[1, 2, 1, 3]
//|[3, 1, 2, 1]
//|[1, 1, 2, 3]
//|[apple, banana, pear]
// END EXPECTED OUTPUT

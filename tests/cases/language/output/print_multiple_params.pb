print();
print("single");
print("Speed:", 120, "KPH");
print(1, 2, 3, 4, 5);
print("a", "b", "c", newline=false);
print("d", "e");
print("newline keyword only:", newline=true);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|
//|single
//|Speed: 120 KPH
//|1 2 3 4 5
//|a b cd e
//|newline keyword only:
// END EXPECTED OUTPUT

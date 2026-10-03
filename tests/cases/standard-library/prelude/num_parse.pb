print(num("85"));
print(num("-12.5"));
print(num("  3.25  "));
print(num("1e3"));
print(num("0"));
print(num("-0.5") + 1);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|85
//|-12.5
//|3.25
//|1000
//|0
//|0.5
// END EXPECTED OUTPUT

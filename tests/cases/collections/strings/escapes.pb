print("quote: \"");
print("slash: \\");
print("line 1\nline 2");
print(len("\\\"\n\r\t"));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|quote: "
//|slash: \
//|line 1
//|line 2
//|5
// END EXPECTED OUTPUT

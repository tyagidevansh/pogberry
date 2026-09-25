use "pb_gui" as gui;
gui.loadShader(42, "x.fs");
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|loadShader(vsPath, fsPath) expected (nil selects the default).
//|[line 2] in script
// END EXPECTED OUTPUT

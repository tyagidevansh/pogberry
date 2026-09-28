use "pb_gui" as gui;
gui.setShaderColor(1, "u_tint", 300, 0, 0, 255);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|setShaderColor(shader, uniformName, r, g, b, a) expected (0-255).
//|[line 2] in script
// END EXPECTED OUTPUT

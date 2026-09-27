use "pb_gui" as gui;
gui.setShaderVec3(1, "u_pos", 1.0, 2.0);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|setShaderVec3(id, uniformName, x, y, z) expected.
//|[line 2] in script
// END EXPECTED OUTPUT

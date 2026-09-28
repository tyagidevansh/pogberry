use "pb_gui" as gui;
let shader = gui.loadShader(nil, "fake.fs");
gui.unloadShader(shader);
gui.beginShaderMode(shader);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|shader has been unloaded.
//|[line 4] in script
// END EXPECTED OUTPUT

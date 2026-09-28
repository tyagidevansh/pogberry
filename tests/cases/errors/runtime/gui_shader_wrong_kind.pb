use "pb_gui" as gui;
let target = gui.loadRenderTexture(64, 64);
gui.beginShaderMode(target);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|beginShaderMode(shader) expected a shader.
//|[line 3] in script
// END EXPECTED OUTPUT

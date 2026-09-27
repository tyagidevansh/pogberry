use "pb_gui" as gui;

let shader = gui.loadShader(nil, "fake.fs");
let tex = gui.loadTexture("fake.png");
gui.setShaderVec3(shader, "u_pos", 1.0, 2.0, 3.0);
gui.setShaderVec4(shader, "u_rect", 0.0, 0.0, 100.0, 50.0);
gui.setShaderColor(shader, "u_tint", 255, 128, 0, 255);
gui.setShaderTexture(shader, "u_detail", tex);
print(shader);
print(tex);
gui.unloadShader(shader);
gui.unloadTexture(tex);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|1
//|1
// END EXPECTED OUTPUT

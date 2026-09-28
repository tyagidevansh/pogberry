use "pb_gui" as gui;

gui.setDebugMode(true);
gui.setTraceLogLevel("ERROR");
gui.setTraceLogLevel("ALL");

let shader = gui.loadShader(nil, "fake.fs");
print(shader);
print(type(shader));
gui.setShaderFloat(shader, "u_time", 1.5);
gui.setShaderVec2(shader, "u_resolution", 800, 600);
gui.beginShaderMode(shader);
gui.endShaderMode();
gui.unloadShader(shader);

let bothPaths = gui.loadShader("fake.vs", "fake.fs");
print(bothPaths);
gui.unloadShader(bothPaths);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|<shader 1>
//|shader
//|<shader 1>
// END EXPECTED OUTPUT

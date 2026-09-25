use "pb_gui" as gui;
gui.loadShader(nil, nil);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|loadShader() failed for vs="(default)" fs="(default)". Check the paths and GLSL, or call gui.setDebugMode(true) for Raylib shader logs.
//|[line 2] in script
// END EXPECTED OUTPUT

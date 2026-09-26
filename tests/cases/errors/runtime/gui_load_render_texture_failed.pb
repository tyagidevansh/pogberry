use "pb_gui" as gui;
gui.loadRenderTexture(100000, 100000);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|loadRenderTexture(100000, 100000) failed. Lower the size or call gui.setDebugMode(true) for Raylib logs.
//|[line 2] in script
// END EXPECTED OUTPUT

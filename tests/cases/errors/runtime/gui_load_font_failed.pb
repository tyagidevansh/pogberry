use "pb_gui" as gui;
gui.loadFont("fake.ttf", 99999);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|loadFont() failed for "fake.ttf". Check the file or call gui.setDebugMode(true).
//|[line 2] in script
// END EXPECTED OUTPUT

use "pb_gui" as gui;

let font = gui.loadFont("fake.ttf", 32);
print(font);
print(type(font));
gui.beginDrawing();
gui.clearBackground(10, 10, 10);
gui.drawTextFont(font, "Hi", 20, 20, 20, 1, 255, 255, 255);
gui.endDrawing();
print(gui.measureTextFont(font, "Hi", 20, 1));
print(gui.measureTextFont(font, "Hi", 20));
print(gui.measureText(font, "Hi", 20));
print(gui.measureTextHeight("Hi", 20));
print(gui.measureTextHeight(font, "Hi", 20));
let size = gui.measureTextEx(font, "Hi", 20);
print(size[0]);
print(size[1]);
let snd = gui.loadSound("fake.wav");
print(snd);
gui.unloadSound(snd);
gui.unloadFont(font);
print(gui.loadFont("missing.ttf", 32));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|<font 1>
//|font
//|40
//|40
//|40
//|20
//|20
//|40
//|20
//|1
//|nil
// END EXPECTED OUTPUT

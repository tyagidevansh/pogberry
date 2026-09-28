use "pb_gui" as gui;

let target = gui.loadRenderTexture(800, 600);
print(target);
gui.beginTextureMode(target);
gui.clearBackground(20, 20, 30);
gui.drawRectangle(10, 10, 40, 40, 255, 0, 0);
gui.endTextureMode();
gui.beginDrawing();
gui.clearBackground(0, 0, 0);
gui.drawRenderTexture(target, 0, 0);
gui.drawRenderTextureRec(target, 0, 0, 40, 40, 100, 100);
gui.endDrawing();
gui.unloadRenderTexture(target);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|<render texture 1>
// END EXPECTED OUTPUT

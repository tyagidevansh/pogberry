use "pb_gui" as gui;

gui.initWindow(800, 600, "headless compact test");

gui.beginDrawing();
gui.clearBackground([10, 20, 30]);
gui.clearBackground(0x0A141E);

gui.drawLine([1, 2], [3, 4], [255, 0, 0]);
gui.drawLine([1, 2], [3, 4], 0xFF0000);
gui.drawCircle([10, 20], 5, [0, 255, 0]);
gui.drawCircleLines([10, 20], 5, 0x00FF00);
gui.drawCircleAlpha([10, 20], 5, [0, 255, 0, 128]);
gui.drawCircleAlpha([10, 20], 5, 0x00FF0080);
gui.drawEllipse([10, 20], [5, 8], [0, 0, 255]);
gui.drawRectangle([10, 20, 30, 40], [100, 110, 120]);
gui.drawRectangle([10, 20, 30, 40], 0x646E78);
gui.drawRectangleLines([10, 20, 30, 40], [100, 110, 120]);
gui.drawRectangleAlpha([10, 20, 30, 40], [100, 110, 120, 200]);
gui.drawRectangleAlpha([10, 20, 30, 40], 0x646E78C8);
gui.drawRectangleRounded([10, 20, 30, 40], 0.5, 4, [100, 110, 120]);
gui.drawText("Compact Pogberry", [10, 20], 24, [255, 255, 255]);
gui.drawText("Compact Hex", [10, 20], 24, 0xFFFFFF);

gui.begin3D([0, 5, -10], [0, 0, 0], 45);
gui.drawCube3D([0, 0, 0], [1, 2, 3], [255, 0, 0]);
gui.drawCube3D([0, 0, 0], 2, 0xFF0000);
gui.drawCubeWires3D([0, 0, 0], [1, 2, 3], [0, 255, 0]);
gui.drawPlane3D([0, 0, 0], [10, 20], [0, 0, 255]);
gui.drawPlane3D([0, 0, 0], 10, 0x0000FF);
gui.drawSphere3D([0, 0, 0], 5, [255, 255, 0]);
gui.drawCylinder3D([0, 0, 0], 2, 2, 5, [10, 20, 30]);
gui.drawCylinder3D([0, 0, 0], [2, 2, 5], 16, 0x0A141E);
gui.drawCylinderWires3D([0, 0, 0], 2, 2, 5, [10, 20, 30]);
gui.drawCylinderWires3D([0, 0, 0], [2, 2, 5], 16, 0x0A141E);
gui.drawTriangle3D([0, 0, 0], [1, 1, 1], [2, 0, 2], [255, 255, 0]);
gui.drawQuad3D([0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0], [255, 0, 0]);
gui.drawQuad3D([0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0], 0xFF0000);
gui.drawQuad3D([[0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0]], [0, 255, 0]);
gui.drawQuad3D([[0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0]], 0x00FF00);
gui.drawQuadStrip3D([[[0,0,0],[1,0,0],[1,1,0],[0,1,0]]], [255, 255, 255]);

let m = gui.loadModel("fake.obj");
gui.drawModel(m, [0, 0, 0], 1.5, [255, 255, 255]);
gui.drawModelWires(m, [0, 0, 0], 1.5, [255, 255, 255]);
gui.drawModelRotY(m, [0, 0, 0], 90, 1.0, [255, 0, 0]);
gui.drawModelWiresRotY(m, [0, 0, 0], 90, 1.0, 0xFF0000);
gui.drawModelEx(m, [0, 0, 0], [0, 1, 0, 90], [1, 1, 1], [255, 255, 255]);
gui.drawModelWiresEx(m, [0, 0, 0], [0, 1, 0, 90], 1.0, 0xFFFFFF);
gui.unloadModel(m);
gui.end3D();

gui.begin3DEx([0, 5, -10], [0, 0, 0], [0, 1, 0], 60);
gui.end3D();

let font = gui.loadFont("fake.ttf", 32);
gui.drawTextFont(font, "Hi", [20, 20], 20, 1, [255, 255, 255]);
gui.drawTextFont(font, "Hi", [20, 20], 20, 1, 0xFFFFFF);
gui.unloadFont(font);

let shader = gui.loadShader(nil, "fake.fs");
gui.setShaderColor(shader, "u_color", [255, 128, 0, 255]);
gui.setShaderColor(shader, "u_color", 0xFF8000FF);
gui.unloadShader(shader);

let shaderSingle = gui.loadShader("fake.fs");
gui.unloadShader(shaderSingle);

let tex = gui.loadTexture("fake.png");
gui.drawTexture(tex, [10, 10]);
gui.drawTextureTint(tex, [10, 10], [200, 200, 200]);
gui.drawTextureTint(tex, [10, 10], 0xC8C8C8);
gui.drawTextureRec(tex, [0, 0, 32, 32], [10, 10]);
gui.drawTexturePro(tex, [0, 0, 32, 32], [10, 10, 64, 64], [0, 0], 0);
gui.drawBillboard(tex, [0, 0, 0], 2.0, [255, 255, 255]);
gui.unloadTexture(tex);

gui.endDrawing();

print(gui.checkCollisionRecs([0, 0, 10, 10], [5, 5, 10, 10]));
print(gui.checkCollisionCircles([0, 0], 10, [5, 5], 10));
print(gui.checkCollisionCircleRec([0, 0], 10, [5, 5, 10, 10]));
print(gui.checkCollisionPointRec([5, 5], [0, 0, 10, 10]));
print(gui.checkCollisionPointCircle([5, 5], [0, 0], 10));
print(gui.isKeyDown("w"));
print(gui.isKeyDown(87));
print(gui.isMouseButtonDown("right"));
print(gui.isMouseButtonDown(1));
gui.setTraceLogLevel("debug");

gui.closeWindow();
print("compact api success");

// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|true
//|true
//|true
//|true
//|true
//|true
//|true
//|true
//|compact api success
// END EXPECTED OUTPUT

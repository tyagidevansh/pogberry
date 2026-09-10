use "pb_gui" as gui;

gui.initWindow(800, 600, "headless test");
gui.setTargetFPS(60);
gui.setExitKey(256);
gui.setWindowTitle("headless test updated");
gui.toggleFullscreen();
gui.toggleBorderlessWindowed();

gui.beginDrawing();
gui.clearBackground(10, 20, 30);
gui.drawPixel(1, 2, 255, 255, 255);
gui.drawLine(1, 2, 3, 4, 255, 0, 0);
gui.drawCircle(10, 20, 5, 0, 255, 0);
gui.drawCircleLines(10, 20, 5, 0, 255, 0);
gui.drawCircleAlpha(10, 20, 5, 0, 255, 0, 128);
gui.drawEllipse(10, 20, 5, 8, 0, 0, 255);
gui.drawRectangle(10, 20, 30, 40, 100, 110, 120);
gui.drawRectangleLines(10, 20, 30, 40, 100, 110, 120);
gui.drawRectangleAlpha(10, 20, 30, 40, 100, 110, 120, 200);
gui.drawRectangleRounded(10, 20, 30, 40, 0.5, 4, 100, 110, 120);
gui.drawFPS(10, 10);
gui.drawText("Pogberry", 10, 20, 24, 255, 255, 255);

let tex = gui.loadTexture("fake.png");
gui.drawTexture(tex, 10, 10);
gui.drawTextureTint(tex, 10, 10, 200, 200, 200);
gui.drawTextureRec(tex, 0, 0, 32, 32, 10, 10);
gui.drawTexturePro(tex, 0, 0, 32, 32, 10, 10, 64, 64, 0, 0, 0);
gui.endDrawing();

gui.setWindowSize(1024, 768);
gui.setWindowPosition(100, 100);
gui.hideCursor();
gui.showCursor();

print(gui.windowShouldClose());
print(gui.isWindowMinimized());
print(gui.isWindowFocused());
print(gui.isWindowResized());
print(gui.getScreenWidth());
print(gui.getScreenHeight());
print(gui.getFPS());
print(gui.getFrameTime());
print(gui.getTime());
print(gui.isWindowFullscreen());
print(gui.measureText("PB", 10));
print(gui.isKeyPressed("KEY_UP"));
print(gui.isKeyPressed("KEY_ZERO"));
print(gui.isKeyDown("KEY_W"));
print(gui.isKeyReleased("KEY_LEFT"));
print(gui.isKeyUp("KEY_SPACE"));
print(gui.getKeyPressed());
print(gui.getCharPressed());
print(gui.isMouseButtonPressed("LEFT"));
print(gui.isMouseButtonDown("RIGHT"));
print(gui.isMouseButtonDown("SIDE"));
print(gui.isMouseButtonReleased("MIDDLE"));
print(gui.isMouseButtonUp("LEFT"));
print(gui.getMouseX());
print(gui.getMouseY());
print(gui.getMouseWheelMove());
print(gui.checkCollisionRecs(0, 0, 10, 10, 5, 5, 10, 10));
print(gui.checkCollisionCircles(0, 0, 10, 5, 5, 10));
print(gui.checkCollisionCircleRec(0, 0, 10, 5, 5, 10, 10));
print(gui.checkCollisionPointRec(5, 5, 0, 0, 10, 10));
print(gui.checkCollisionPointCircle(5, 5, 0, 0, 10));

print(tex);
print(gui.getTextureWidth(tex));
print(gui.getTextureHeight(tex));
gui.unloadTexture(tex);

gui.initAudio();
gui.setMasterVolume(0.8);
let snd = gui.loadSound("fake.wav");
print(snd);
gui.playSound(snd);
gui.setSoundVolume(snd, 0.5);
gui.setSoundPitch(snd, 1.2);
print(gui.isSoundPlaying(snd));
gui.stopSound(snd);
gui.unloadSound(snd);

let mus = gui.loadMusic("fake.mp3");
print(mus);
gui.playMusic(mus);
gui.updateMusic(mus);
gui.pauseMusic(mus);
gui.resumeMusic(mus);
print(gui.isMusicStreamPlaying(mus));
gui.setMusicVolume(mus, 0.7);
gui.stopMusic(mus);
gui.unloadMusic(mus);
gui.closeAudio();

print(gui.isWindowMaximized());
gui.maximizeWindow();
gui.restoreWindow();
gui.setVirtualResolution(800, 450);
print(gui.getScreenWidth());
print(gui.getScreenHeight());
print(gui.getRenderWidth());
print(gui.getRenderHeight());
gui.closeWindow();
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|false
//|true
//|true
//|800
//|600
//|60
//|0.016
//|1.25
//|true
//|20
//|true
//|true
//|true
//|true
//|true
//|265
//|65
//|true
//|true
//|true
//|true
//|true
//|123
//|456
//|2.5
//|true
//|true
//|true
//|true
//|true
//|1
//|64
//|64
//|1
//|false
//|1
//|true
//|false
//|800
//|450
//|800
//|600
// END EXPECTED OUTPUT

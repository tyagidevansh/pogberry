use "pb_gui" as gui;
use "config" as config;
use "game" as game;

gui.initWindow(config.width, config.height, "Target Practice");
gui.setTargetFPS(60);

let session = game.Game();
while (!gui.windowShouldClose())
{
  session.update();
  session.draw();
}

gui.closeWindow();

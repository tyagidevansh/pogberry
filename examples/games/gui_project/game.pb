use "pb_gui" as gui;
use "config" as config;
use "target" as target;

export class Game
{
  init()
  {
    this.score = 0;
    this.target = target.Target();
  }

  update()
  {
    if (gui.isMouseButtonPressed("LEFT"))
    {
      let mouseX = gui.getMouseX();
      let mouseY = gui.getMouseY();
      if (this.target.contains(mouseX, mouseY))
      {
        this.score = this.score + 1;
        this.target.respawn();
      }
    }
  }

  draw()
  {
    let background = config.background;
    let targetColor = config.targetColor;
    let textColor = config.textColor;

    gui.beginDrawing();
    gui.clearBackground(background[0], background[1], background[2]);
    gui.drawRectangle(this.target.x, this.target.y,
                      this.target.size, this.target.size,
                      targetColor[0], targetColor[1], targetColor[2]);
    gui.drawText("Score: " + str(this.score), 20, 20, 28,
                 textColor[0], textColor[1], textColor[2]);
    gui.drawText("Click the red target", 20, 55, 20,
                 textColor[0], textColor[1], textColor[2]);
    gui.endDrawing();
  }
}

use "pb_gui" as gui;

export class TextField
{
  init(maxLength)
  {
    this.text = "";
    this.cursor = 0;
    this.focused = false;
    this.submitted = false;
    this.cancelled = false;
    this.backTimer = 0;
    this.maxLength = maxLength;
  }

  insertChar(ch)
  {
    if (ch == "\n" or ch == "\r" or ch == "\t") return nil;
    if (len(ch) != 1) return nil;
    if (this.maxLength > 0 and len(this.text) >= this.maxLength) return nil;
    this.text = this.text.substr(0, this.cursor) + ch + this.text.substr(this.cursor);
    this.cursor = this.cursor + 1;
    return nil;
  }

  eraseOne()
  {
    if (this.cursor <= 0) return nil;
    this.text = this.text.substr(0, this.cursor - 1) + this.text.substr(this.cursor);
    this.cursor = this.cursor - 1;
    return nil;
  }

  moveCursor(delta)
  {
    this.cursor = this.cursor + delta;
    if (this.cursor < 0) this.cursor = 0;
    if (this.cursor > len(this.text)) this.cursor = len(this.text);
    return nil;
  }

  update(dt)
  {
    if (!this.focused) return nil;
    let n = 0;
    let ch = gui.readChar();
    while (ch != "" and n < 16)
    {
      this.insertChar(ch);
      n = n + 1;
      ch = gui.readChar();
    }
    if (gui.isKeyPressed("KEY_BACKSPACE"))
    {
      this.eraseOne();
      this.backTimer = 0;
    }
    else if (gui.isKeyDown("KEY_BACKSPACE"))
    {
      this.backTimer = this.backTimer + dt;
      if (this.backTimer >= 0.4)
      {
        this.eraseOne();
        this.backTimer = this.backTimer - 0.05;
      }
    }
    else this.backTimer = 0;
    if (gui.isKeyPressed("KEY_LEFT")) this.moveCursor(-1);
    if (gui.isKeyPressed("KEY_RIGHT")) this.moveCursor(1);
    if (gui.isKeyPressed("KEY_ENTER")) this.submitted = true;
    if (gui.isKeyPressed("KEY_ESCAPE")) this.cancelled = true;
    return nil;
  }
}

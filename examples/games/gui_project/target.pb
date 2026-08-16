use "config" as config;

export class Target
{
  init()
  {
    this.size = config.targetSize;
    this.respawn();
  }

  respawn()
  {
    this.x = rand(config.width - this.size);
    this.y = rand(config.height - this.size);
  }

  contains(x, y)
  {
    return x >= this.x and x <= this.x + this.size and
           y >= this.y and y <= this.y + this.size;
  }
}

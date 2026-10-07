use "pb_gui" as gui;
use "pb.time" as time;
use "config";
use "assets";
use "particles";
use "player";
use "world";

gui.initWindow(800, 450, "profile");
gui.setTargetFPS(60);
assets.init();

let playerObj = player.Player();
let worldObj = world.World();
let particleSys = particles.ParticleSystem();

let frames = 600;
let start = time.cpu();
let f = 0;
while (f < frames)
{
  if (!playerObj.isAlive)
  {
    playerObj.reset();
    worldObj.reset();
    particleSys.clear();
  }
  if (f % 90 == 0) playerObj.jump(particleSys);
  worldObj.update(0.016, playerObj, particleSys);
  playerObj.update(0.016, particleSys);
  particleSys.update(0.016);
  gui.beginDrawing();
  gui.clearBackground(config.colorBgR, config.colorBgG, config.colorBgB);
  worldObj.drawParallax();
  worldObj.draw();
  playerObj.draw();
  particleSys.draw();
  gui.endDrawing();
  f = f + 1;
}
let elapsed = time.cpu() - start;
print(frames);
print(elapsed);
print(elapsed / frames * 1000.0);

assets.cleanup();
gui.closeWindow();

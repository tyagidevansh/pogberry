use "pb_gui" as gui;

export let texBgSkyline = 0;
export let texBgBuildings = 0;
export let texBgForeground = 0;
export let texScarfy = 0;
export let texExplosion = 0;

export let sndJump = 0;
export let sndCoin = 0;
export let sndStomp = 0;
export let sndBoom = 0;
export let bgMusic = 0;

export let isMuted = false;

fun loadTextureFile(filename)
{
  let t = gui.loadTexture("examples/games/cyber_runner/assets/" + filename);
  if (t == 0)
    t = gui.loadTexture("assets/" + filename);
  return t;
}

fun loadSoundFile(filename)
{
  let s = gui.loadSound("examples/games/cyber_runner/assets/" + filename);
  if (s == 0)
    s = gui.loadSound("assets/" + filename);
  return s;
}

fun loadMusicFile(filename)
{
  let m = gui.loadMusic("examples/games/cyber_runner/assets/" + filename);
  if (m == 0)
    m = gui.loadMusic("assets/" + filename);
  return m;
}

export fun init()
{
  texBgSkyline = loadTextureFile("cyberpunk_street_background.png");
  texBgBuildings = loadTextureFile("cyberpunk_street_midground.png");
  texBgForeground = loadTextureFile("cyberpunk_street_foreground.png");
  texScarfy = loadTextureFile("scarfy.png");
  texExplosion = loadTextureFile("explosion.png");

  gui.initAudio();
  sndJump = loadSoundFile("spring.wav");
  sndCoin = loadSoundFile("coin.wav");
  sndStomp = loadSoundFile("sound.wav");
  sndBoom = loadSoundFile("boom.wav");
  bgMusic = loadMusicFile("bgm.mp3");

  if (bgMusic != 0)
  {
    gui.setMusicVolume(bgMusic, 0.45);
    gui.playMusic(bgMusic);
  }
}

export fun playJump()
{
  if (isMuted or sndJump == 0) return;
  let pitch = 0.95 + (rand(20) / 100.0);
  gui.setSoundPitch(sndJump, pitch);
  gui.setSoundVolume(sndJump, 0.6);
  gui.playSound(sndJump);
}

export fun playCoin()
{
  if (isMuted or sndCoin == 0) return;
  let pitch = 0.95 + (rand(25) / 100.0);
  gui.setSoundPitch(sndCoin, pitch);
  gui.setSoundVolume(sndCoin, 0.55);
  gui.playSound(sndCoin);
}

export fun playStomp()
{
  if (isMuted or sndStomp == 0) return;
  let pitch = 1.0 + (rand(15) / 100.0);
  gui.setSoundPitch(sndStomp, pitch);
  gui.setSoundVolume(sndStomp, 0.7);
  gui.playSound(sndStomp);
}

export fun playBoom()
{
  if (isMuted or sndBoom == 0) return;
  gui.setSoundVolume(sndBoom, 0.85);
  gui.playSound(sndBoom);
}

export fun toggleMute()
{
  isMuted = !isMuted;
  if (isMuted)
  {
    gui.setMasterVolume(0.0);
  }
  else
  {
    gui.setMasterVolume(1.0);
  }
}

export fun updateMusic()
{
  if (bgMusic != 0)
  {
    gui.updateMusic(bgMusic);
  }
}

export fun pauseMusic()
{
  if (bgMusic != 0)
  {
    gui.pauseMusic(bgMusic);
  }
}

export fun resumeMusic()
{
  if (bgMusic != 0)
  {
    gui.resumeMusic(bgMusic);
  }
}

export fun cleanup()
{
  if (bgMusic != 0) gui.unloadMusic(bgMusic);
  if (sndJump != 0) gui.unloadSound(sndJump);
  if (sndCoin != 0) gui.unloadSound(sndCoin);
  if (sndStomp != 0) gui.unloadSound(sndStomp);
  if (sndBoom != 0) gui.unloadSound(sndBoom);

  if (texBgSkyline != 0) gui.unloadTexture(texBgSkyline);
  if (texBgBuildings != 0) gui.unloadTexture(texBgBuildings);
  if (texBgForeground != 0) gui.unloadTexture(texBgForeground);
  if (texScarfy != 0) gui.unloadTexture(texScarfy);
  if (texExplosion != 0) gui.unloadTexture(texExplosion);

  gui.closeAudio();
}


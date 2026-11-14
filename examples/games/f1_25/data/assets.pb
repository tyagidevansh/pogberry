use "pb_gui" as gui;
use "data/constants" as const;

export class AssetManager {
  init(baseDir) {
    this.baseDir = baseDir;
    this.modelsDir = baseDir + "/assets/models";
    this.audioDir = baseDir + "/assets/audio";

    this.modelFerrari = 0;
    this.modelRedBull = 0;
    this.modelMercedes = 0;
    this.modelMcLaren = 0;
    this.modelPhantom = 0;
    this.modelValkyrie = 0;
    this.modelShinobi = 0;
    this.modelVanta = 0;
    this.modelRivalFormula = 0;
    this.modelDelivery = 0;
    this.modelTruck = 0;
    this.modelSedan = 0;
    this.modelTaxi = 0;
    this.modelAmbulance = 0;
    this.modelCone = 0;
    this.modelBox = 0;
    this.modelBuildingA = 0;
    this.modelBuildingB = 0;
    this.modelBuildingC = 0;
    this.modelBuildingD = 0;
    this.modelGarage = 0;
    this.modelTreeLarge = 0;
    this.modelTreeSmall = 0;
    this.modelGrandStand = 0;
    this.modelGrandStandCovered = 0;
    this.modelBillboard = 0;
    this.modelOverheadLights = 0;
    this.modelLightPost = 0;
    this.modelPitsGarage = 0;
    this.modelBarrierRed = 0;
    this.modelBarrierWhite = 0;
    this.modelFenceStraight = 0;
    this.modelFlagCheckers = 0;
    this.modelBannerTower = 0;
    this.modelTent = 0;
    this.modelTentLong = 0;
    this.modelPitsOffice = 0;
    this.modelRadar = 0;
    this.modelFlagTankco = 0;
    this.modelFlagRed = 0;
    this.modelLightPostLarge = 0;
    this.modelBillboardDouble = 0;
    this.modelGrandStandAwning = 0;

    this.sndCountdownLow = 0;
    this.sndCountdownHigh = 0;
    this.sndCheckpoint = 0;
    this.sndSelect = 0;
    this.sndConfirm = 0;
    this.sndNitro = 0;
    this.sndSkid = 0;
    this.sndCrash = 0;
    this.sndExplode = 0;
    this.sndWin = 0;
    this.sndEngineStart = 0;

    this.musicCruise = 0;
    this.musicClimax = 0;
    this.activeMusic = 0;
    this.musicMuted = false;

    this.shaderVelocity = nil;
  }

  loadAll() {
    gui.initAudio();

    this.modelFerrari = gui.loadModel(this.modelsDir + "/car_ferrari.obj");
    this.modelRedBull = gui.loadModel(this.modelsDir + "/car_redbull.obj");
    this.modelMercedes = gui.loadModel(this.modelsDir + "/car_mercedes.obj");
    this.modelMcLaren = gui.loadModel(this.modelsDir + "/car_mclaren.obj");
    this.modelPhantom = gui.loadModel(this.modelsDir + "/race-future.obj");
    this.modelValkyrie = gui.loadModel(this.modelsDir + "/suv-luxury.obj");
    this.modelShinobi = gui.loadModel(this.modelsDir + "/sedan-sports.obj");
    this.modelVanta = gui.loadModel(this.modelsDir + "/police.obj");
    this.modelRivalFormula = gui.loadModel(this.modelsDir + "/race.obj");
    this.modelDelivery = gui.loadModel(this.modelsDir + "/delivery.obj");
    this.modelTruck = gui.loadModel(this.modelsDir + "/truck.obj");
    this.modelSedan = gui.loadModel(this.modelsDir + "/sedan.obj");
    this.modelTaxi = gui.loadModel(this.modelsDir + "/taxi.obj");
    this.modelAmbulance = gui.loadModel(this.modelsDir + "/ambulance.obj");
    this.modelCone = gui.loadModel(this.modelsDir + "/cone.obj");
    this.modelBox = gui.loadModel(this.modelsDir + "/box.obj");

    this.modelBuildingA = gui.loadModel(this.modelsDir + "/building-small-a.glb");
    this.modelBuildingB = gui.loadModel(this.modelsDir + "/building-small-b.glb");
    this.modelBuildingC = gui.loadModel(this.modelsDir + "/building-small-c.glb");
    this.modelBuildingD = gui.loadModel(this.modelsDir + "/building-small-d.glb");
    this.modelGarage = gui.loadModel(this.modelsDir + "/building-garage.glb");

    this.modelTreeLarge = gui.loadModel(this.modelsDir + "/treeLarge.glb");
    this.modelTreeSmall = gui.loadModel(this.modelsDir + "/treeSmall.glb");
    this.modelGrandStand = gui.loadModel(this.modelsDir + "/grandStand.glb");
    this.modelGrandStandCovered = gui.loadModel(this.modelsDir + "/grandStandCovered.glb");
    this.modelBillboard = gui.loadModel(this.modelsDir + "/billboard.glb");
    this.modelOverheadLights = gui.loadModel(this.modelsDir + "/overheadLights.glb");
    this.modelLightPost = gui.loadModel(this.modelsDir + "/lightPostModern.glb");
    this.modelPitsGarage = gui.loadModel(this.modelsDir + "/pitsGarage.glb");
    this.modelBarrierRed = gui.loadModel(this.modelsDir + "/barrierRed.glb");
    this.modelBarrierWhite = gui.loadModel(this.modelsDir + "/barrierWhite.glb");
    this.modelFenceStraight = gui.loadModel(this.modelsDir + "/fenceStraight.glb");
    this.modelFlagCheckers = gui.loadModel(this.modelsDir + "/flagCheckers.glb");
    this.modelBannerTower = gui.loadModel(this.modelsDir + "/bannerTowerRed.glb");
    this.modelTent = gui.loadModel(this.modelsDir + "/tent.glb");
    this.modelTentLong = gui.loadModel(this.modelsDir + "/tentLong.glb");
    this.modelPitsOffice = gui.loadModel(this.modelsDir + "/pitsOffice.glb");
    this.modelRadar = gui.loadModel(this.modelsDir + "/radarEquipment.glb");
    this.modelFlagTankco = gui.loadModel(this.modelsDir + "/flagTankco.glb");
    this.modelFlagRed = gui.loadModel(this.modelsDir + "/flagRed.glb");
    this.modelLightPostLarge = gui.loadModel(this.modelsDir + "/lightPostLarge.glb");
    this.modelBillboardDouble = gui.loadModel(this.modelsDir + "/billboardDouble_exclusive.glb");
    this.modelGrandStandAwning = gui.loadModel(this.modelsDir + "/grandStandAwning.glb");

    this.sndCountdownLow = gui.loadSound(this.audioDir + "/countdown_low.wav");
    this.sndCountdownHigh = gui.loadSound(this.audioDir + "/countdown_high.wav");
    this.sndCheckpoint = gui.loadSound(this.audioDir + "/checkpoint.wav");
    this.sndSelect = gui.loadSound(this.audioDir + "/ui_select.wav");
    this.sndConfirm = gui.loadSound(this.audioDir + "/ui_confirm.wav");
    this.sndNitro = gui.loadSound(this.audioDir + "/nitro.wav");
    this.sndSkid = gui.loadSound(this.audioDir + "/skid.wav");
    this.sndCrash = gui.loadSound(this.audioDir + "/crash.wav");
    this.sndExplode = this.sndCrash;
    this.sndWin = gui.loadSound(this.audioDir + "/win.wav");
    this.sndEngineStart = gui.loadSound(this.baseDir + "/assets/engine-start.wav");

    if (this.sndEngineStart > 0) gui.setSoundVolume(this.sndEngineStart, 0.45);
    if (this.sndNitro > 0) gui.setSoundVolume(this.sndNitro, 0.55);
    if (this.sndSkid > 0) gui.setSoundVolume(this.sndSkid, 0.35);
    if (this.sndCrash > 0) gui.setSoundVolume(this.sndCrash, 0.60);
    if (this.sndCheckpoint > 0) gui.setSoundVolume(this.sndCheckpoint, 0.50);
    if (this.sndCountdownLow > 0) gui.setSoundVolume(this.sndCountdownLow, 0.55);
    if (this.sndCountdownHigh > 0) gui.setSoundVolume(this.sndCountdownHigh, 0.65);
    if (this.sndSelect > 0) gui.setSoundVolume(this.sndSelect, 0.40);
    if (this.sndConfirm > 0) gui.setSoundVolume(this.sndConfirm, 0.50);

    this.musicCruise = gui.loadMusic(this.baseDir + "/assets/neon-sign-circuit.ogg");
    this.musicClimax = gui.loadMusic(this.baseDir + "/assets/neon-sign-circuit-climax.ogg");
    if (this.musicCruise > 0) {
      gui.setMusicVolume(this.musicCruise, 0.40);
      gui.playMusic(this.musicCruise);
      this.activeMusic = this.musicCruise;
    }
    if (this.musicClimax > 0) {
      gui.setMusicVolume(this.musicClimax, 0.40);
    }

    this.shaderVelocity = gui.loadShader(nil, this.baseDir + "/assets/velocity.fs");
  }

  playCarModel(carId, x, y, z, rotY, scale, r, g, b) {
    let m = this.modelRedBull;
    if (carId == 0) m = this.modelRedBull;
    else if (carId == 1) m = this.modelMercedes;
    else if (carId == 2) m = this.modelFerrari;
    else m = this.modelMcLaren;

    if (m > 0) {
      gui.drawModelRotY(m, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCube3D([x, y + 0.5, z], [1.8, 0.6, 3.2], [r, g, b]);
    }
  }

  playTrafficModel(typeId, x, y, z, rotY, scale, r, g, b) {
    let m = this.modelDelivery;
    if (typeId == 1) m = this.modelTruck;
    else if (typeId == 2) m = this.modelSedan;
    else if (typeId == 3) m = this.modelTaxi;
    else if (typeId == 4) m = this.modelAmbulance;
    else if (typeId == 5) m = this.modelRivalFormula;

    if (m > 0) {
      gui.drawModelRotY(m, [x, y, z], rotY, scale, [r, g, b]);
    } else {
      gui.drawCube3D([x, y + 0.6, z], [1.9, 0.8, 3.4], [r, g, b]);
    }
  }

  playBuildingModel(variant, x, y, z, scale, rotY) {
    let m = this.modelBuildingA;
    if (variant == 1) m = this.modelBuildingB;
    else if (variant == 2) m = this.modelBuildingC;
    else if (variant == 3) m = this.modelBuildingD;

    if (m > 0) {
      gui.drawModelRotY(m, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCube3D([x, y + scale * 4.0, z], [scale * 3.0, scale * 8.0, scale * 3.0], [40, 45, 65]);
    }
  }

  playHazardCone(x, y, z, scale) {
    if (this.modelCone > 0) {
      gui.drawModel(this.modelCone, [x, y, z], scale, [255, 120, 20]);
    } else {
      gui.drawCylinder3D([x, y + 0.5, z], [0.05, 0.4, 0.9], 8, [255, 120, 20]);
    }
  }

  playHazardBox(x, y, z, scale) {
    if (this.modelBox > 0) {
      gui.drawModel(this.modelBox, [x, y, z], scale, [210, 180, 110]);
    } else {
      gui.drawCube3D([x, y + scale * 0.5, z], [scale, scale, scale], [210, 180, 110]);
    }
  }

  playTree(variant, x, y, z, scale, rotY) {
    let m = this.modelTreeLarge;
    if (variant == 1) m = this.modelTreeSmall;
    if (m > 0) {
      gui.drawModelRotY(m, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCylinder3D([x, y + scale * 0.5, z], [0.2, scale * 0.4, scale], 6, [20, 80, 30]);
    }
  }

  playGrandstand(variant, x, y, z, scale, rotY, r, g, b) {
    let m = this.modelGrandStand;
    if (variant == 1) m = this.modelGrandStandCovered;
    if (m > 0) {
      gui.drawModelRotY(m, [x, y, z], rotY, scale, [r, g, b]);
    } else {
      gui.drawCube3D([x, y + scale * 0.4, z], [scale, scale * 0.8, scale], [r, g, b]);
    }
  }

  playBillboard(x, y, z, scale, rotY) {
    if (this.modelBillboard > 0) {
      gui.drawModelRotY(this.modelBillboard, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCube3D([x, y + scale * 0.5, z], [0.3, scale, scale * 1.5], [255, 200, 40]);
    }
  }

  playGantry(x, y, z, scale, rotY) {
    if (this.modelOverheadLights > 0) {
      let centeredX = x - 0.50 * scale;
      gui.drawModelRotY(this.modelOverheadLights, [centeredX, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCube3D([x, y + 4.0, z], [16.0, 0.4, 0.4], [180, 190, 210]);
    }
  }

  playLightPost(x, y, z, scale, rotY) {
    if (this.modelLightPost > 0) {
      gui.drawModelRotY(this.modelLightPost, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCylinder3D([x, y + scale * 0.5, z], [0.1, 0.1, scale], 4, [160, 170, 180]);
    }
  }

  playPitsGarage(x, y, z, scale, rotY, r, g, b) {
    if (this.modelPitsGarage > 0) {
      gui.drawModelRotY(this.modelPitsGarage, [x, y, z], rotY, scale, [r, g, b]);
    } else {
      gui.drawCube3D([x, y + scale * 0.5, z], [scale, scale, scale], [r, g, b]);
    }
  }

  playBannerTower(x, y, z, scale, rotY) {
    if (this.modelBannerTower > 0) {
      gui.drawModelRotY(this.modelBannerTower, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCube3D([x, y + scale * 0.5, z], [scale * 0.2, scale, scale * 0.2], [220, 30, 40]);
    }
  }

  playFlagCheckers(x, y, z, scale, rotY) {
    if (this.modelFlagCheckers > 0) {
      gui.drawModelRotY(this.modelFlagCheckers, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCylinder3D([x, y + scale * 0.5, z], [0.05, 0.05, scale], 4, [255, 255, 255]);
    }
  }

  playTent(variant, x, y, z, scale, rotY, r, g, b) {
    let m = this.modelTent;
    if (variant == 1) m = this.modelTentLong;
    if (m > 0) {
      gui.drawModelRotY(m, [x, y, z], rotY, scale, [r, g, b]);
    } else {
      gui.drawCube3D([x, y + scale * 0.4, z], [scale, scale * 0.8, scale], [r, g, b]);
    }
  }

  playPitsOffice(x, y, z, scale, rotY, r, g, b) {
    if (this.modelPitsOffice > 0) {
      gui.drawModelRotY(this.modelPitsOffice, [x, y, z], rotY, scale, [r, g, b]);
    } else {
      gui.drawCube3D([x, y + scale * 0.6, z], [scale, scale * 1.2, scale], [r, g, b]);
    }
  }

  playRadar(x, y, z, scale, rotY) {
    if (this.modelRadar > 0) {
      gui.drawModelRotY(this.modelRadar, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCube3D([x, y + scale * 0.5, z], [0.4, scale, 0.4], [200, 210, 220]);
    }
  }

  playTrackFlag(variant, x, y, z, scale, rotY) {
    let m = this.modelFlagTankco;
    if (variant == 1) m = this.modelFlagRed;
    if (m > 0) {
      gui.drawModelRotY(m, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCylinder3D([x, y + scale * 0.5, z], [0.04, 0.04, scale], 4, [255, 40, 50]);
    }
  }

  playLargeFloodlight(x, y, z, scale, rotY) {
    if (this.modelLightPostLarge > 0) {
      gui.drawModelRotY(this.modelLightPostLarge, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCylinder3D([x, y + scale * 0.5, z], [0.15, 0.15, scale], 4, [180, 190, 200]);
    }
  }

  playDoubleBillboard(x, y, z, scale, rotY) {
    if (this.modelBillboardDouble > 0) {
      gui.drawModelRotY(this.modelBillboardDouble, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCube3D([x, y + scale * 0.5, z], [0.4, scale, scale * 2.0], [255, 220, 50]);
    }
  }

  playGrandstandAwning(x, y, z, scale, rotY, r, g, b) {
    if (this.modelGrandStandAwning > 0) {
      gui.drawModelRotY(this.modelGrandStandAwning, [x, y, z], rotY, scale, [r, g, b]);
    } else {
      gui.drawCube3D([x, y + scale * 0.4, z], [scale, scale * 0.8, scale], [r, g, b]);
    }
  }

  playPaddockHauler(x, y, z, scale, rotY, r, g, b) {
    if (this.modelTruck > 0) {
      gui.drawModelRotY(this.modelTruck, [x, y, z], rotY, scale, [r, g, b]);
    } else {
      gui.drawCube3D([x, y + 1.2, z], [2.2, 2.4, 6.5], [r, g, b]);
    }
  }

  playFenceStraight(x, y, z, scale, rotY) {
    if (this.modelFenceStraight > 0) {
      gui.drawModelRotY(this.modelFenceStraight, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCube3D([x, y + scale * 0.5, z], [scale * 2.0, scale, 0.1], [190, 195, 205]);
    }
  }

  playBarrier(variant, x, y, z, scale, rotY) {
    let m = this.modelBarrierRed;
    if (variant == 1) m = this.modelBarrierWhite;
    if (m > 0) {
      gui.drawModelRotY(m, [x, y, z], rotY, scale, [255, 255, 255]);
    } else {
      gui.drawCube3D([x, y + scale * 0.4, z], [scale * 1.5, scale * 0.8, 0.4], [220, 40, 50]);
    }
  }

  updateAudio(isClimaxWanted) {
    if (this.musicCruise > 0) gui.updateMusic(this.musicCruise);
    if (this.musicClimax > 0) gui.updateMusic(this.musicClimax);

    if (this.musicMuted) return;

    if (isClimaxWanted and this.activeMusic != this.musicClimax and this.musicClimax > 0) {
      if (this.musicCruise > 0) gui.stopMusic(this.musicCruise);
      gui.playMusic(this.musicClimax);
      this.activeMusic = this.musicClimax;
    } else if (!isClimaxWanted and this.activeMusic != this.musicCruise and this.musicCruise > 0) {
      if (this.musicClimax > 0) gui.stopMusic(this.musicClimax);
      gui.playMusic(this.musicCruise);
      this.activeMusic = this.musicCruise;
    }
  }

  toggleMute() {
    this.musicMuted = !this.musicMuted;
    let vol = 0.40;
    if (this.musicMuted) vol = 0.0;
    if (this.musicCruise > 0) gui.setMusicVolume(this.musicCruise, vol);
    if (this.musicClimax > 0) gui.setMusicVolume(this.musicClimax, vol);
  }

  playSfx(snd) {
    if (snd > 0) gui.playSound(snd);
  }

  unloadAll() {

    if (this.modelFerrari > 0) gui.unloadModel(this.modelFerrari);
    if (this.modelRedBull > 0) gui.unloadModel(this.modelRedBull);
    if (this.modelMercedes > 0) gui.unloadModel(this.modelMercedes);
    if (this.modelMcLaren > 0) gui.unloadModel(this.modelMcLaren);
    if (this.modelPhantom > 0) gui.unloadModel(this.modelPhantom);
    if (this.modelValkyrie > 0) gui.unloadModel(this.modelValkyrie);
    if (this.modelShinobi > 0) gui.unloadModel(this.modelShinobi);
    if (this.modelVanta > 0) gui.unloadModel(this.modelVanta);
    if (this.modelRivalFormula > 0) gui.unloadModel(this.modelRivalFormula);
    if (this.modelDelivery > 0) gui.unloadModel(this.modelDelivery);
    if (this.modelTruck > 0) gui.unloadModel(this.modelTruck);
    if (this.modelSedan > 0) gui.unloadModel(this.modelSedan);
    if (this.modelTaxi > 0) gui.unloadModel(this.modelTaxi);
    if (this.modelAmbulance > 0) gui.unloadModel(this.modelAmbulance);
    if (this.modelCone > 0) gui.unloadModel(this.modelCone);
    if (this.modelBox > 0) gui.unloadModel(this.modelBox);
    if (this.modelBuildingA > 0) gui.unloadModel(this.modelBuildingA);
    if (this.modelBuildingB > 0) gui.unloadModel(this.modelBuildingB);
    if (this.modelBuildingC > 0) gui.unloadModel(this.modelBuildingC);
    if (this.modelBuildingD > 0) gui.unloadModel(this.modelBuildingD);
    if (this.modelGarage > 0) gui.unloadModel(this.modelGarage);
    if (this.modelTreeLarge > 0) gui.unloadModel(this.modelTreeLarge);
    if (this.modelTreeSmall > 0) gui.unloadModel(this.modelTreeSmall);
    if (this.modelGrandStand > 0) gui.unloadModel(this.modelGrandStand);
    if (this.modelGrandStandCovered > 0) gui.unloadModel(this.modelGrandStandCovered);
    if (this.modelBillboard > 0) gui.unloadModel(this.modelBillboard);
    if (this.modelOverheadLights > 0) gui.unloadModel(this.modelOverheadLights);
    if (this.modelLightPost > 0) gui.unloadModel(this.modelLightPost);
    if (this.modelPitsGarage > 0) gui.unloadModel(this.modelPitsGarage);
    if (this.modelBarrierRed > 0) gui.unloadModel(this.modelBarrierRed);
    if (this.modelBarrierWhite > 0) gui.unloadModel(this.modelBarrierWhite);
    if (this.modelFenceStraight > 0) gui.unloadModel(this.modelFenceStraight);
    if (this.modelFlagCheckers > 0) gui.unloadModel(this.modelFlagCheckers);
    if (this.modelBannerTower > 0) gui.unloadModel(this.modelBannerTower);
    if (this.modelTent > 0) gui.unloadModel(this.modelTent);
    if (this.modelTentLong > 0) gui.unloadModel(this.modelTentLong);
    if (this.modelPitsOffice > 0) gui.unloadModel(this.modelPitsOffice);
    if (this.modelRadar > 0) gui.unloadModel(this.modelRadar);
    if (this.modelFlagTankco > 0) gui.unloadModel(this.modelFlagTankco);
    if (this.modelFlagRed > 0) gui.unloadModel(this.modelFlagRed);
    if (this.modelLightPostLarge > 0) gui.unloadModel(this.modelLightPostLarge);
    if (this.modelBillboardDouble > 0) gui.unloadModel(this.modelBillboardDouble);
    if (this.modelGrandStandAwning > 0) gui.unloadModel(this.modelGrandStandAwning);

    if (this.sndCountdownLow > 0) gui.unloadSound(this.sndCountdownLow);
    if (this.sndCountdownHigh > 0) gui.unloadSound(this.sndCountdownHigh);
    if (this.sndCheckpoint > 0) gui.unloadSound(this.sndCheckpoint);
    if (this.sndSelect > 0) gui.unloadSound(this.sndSelect);
    if (this.sndConfirm > 0) gui.unloadSound(this.sndConfirm);
    if (this.sndNitro > 0) gui.unloadSound(this.sndNitro);
    if (this.sndSkid > 0) gui.unloadSound(this.sndSkid);
    if (this.sndCrash > 0) gui.unloadSound(this.sndCrash);
    if (this.sndWin > 0) gui.unloadSound(this.sndWin);
    if (this.sndEngineStart > 0) gui.unloadSound(this.sndEngineStart);

    if (this.musicCruise > 0) gui.unloadMusic(this.musicCruise);
    if (this.musicClimax > 0) gui.unloadMusic(this.musicClimax);
    if (this.shaderVelocity != nil) gui.unloadShader(this.shaderVelocity);

    gui.closeAudio();
  }
}

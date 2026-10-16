use "std.camera";

let cam = camera.Camera(800, 450);
print(cam.x == 0 and cam.y == 0 and cam.zoom == 1);

cam.snapTo(400, 225);
print(cam.x == 0 and cam.y == 0);

cam.snapTo(1000, 500);
print(cam.x == 600 and cam.y == 275);

let f = camera.Camera(800, 450);
f.follow(400, 225, 0, 0.016);
print(f.x == 0 and f.y == 0);
f.follow(800, 225, 5, 0.2);
print(f.x == 400 and f.y == 0);

let c = camera.Camera(800, 450);
c.snapTo(-1000, -1000);
c.clampTo(0, 0, 1200, 800);
print(c.x == 0 and c.y == 0);
c.snapTo(5000, 5000);
c.clampTo(0, 0, 1200, 800);
print(c.x == 1200 and c.y == 800);
c.snapTo(0, 0);
c.clampTo(100, 100, 50, 50);
print(c.x == 75 and c.y == 75);

let t = camera.Camera(800, 450);
t.snapTo(100, 50);
print(t.applyX(100) == 400 and t.applyY(50) == 225);
print(t.applyX(150) == 450 and t.applyY(70) == 245);
print(t.worldX(450) == 150 and t.worldY(245) == 70);

t.setZoom(2);
t.snapTo(200, 200);
print(t.x == 0 and t.y == 87.5);
print(t.applyX(200) == 400 and t.applyY(200) == 225);
print(t.worldX(400) == 200 and t.worldY(225) == 200);
t.setZoom(0);
print(t.zoom == 2);
t.setZoom(100);
print(t.zoom == 4);

let v = camera.Camera(800, 450);
v.snapTo(400, 225);
print(v.isVisible(0, 0, 10, 10, 0));
print(v.isVisible(2000, 2000, 10, 10, 0));
print(v.isVisible(810, 10, 10, 10, 0));
print(v.isVisible(810, 10, 10, 10, 20));

seed(7);
let s = camera.Camera(800, 450);
s.addShake(0.5);
print(s.trauma == 0.5);
s.update(0.016);
print(s.trauma > 0 and s.trauma < 0.5);
let bound = s.maxShake * s.trauma * s.trauma + 0.001;
print(s.shakeX >= 0 - bound and s.shakeX <= bound);
print(s.shakeY >= 0 - bound and s.shakeY <= bound);
s.addShake(5);
print(s.trauma == 1);
for (let i = 0; i < 200; i = i + 1) s.update(0.016);
print(s.trauma == 0 and s.shakeX == 0 and s.shakeY == 0);
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
//|true
//|true
//|true
//|true
//|true
//|true
//|true
//|true
//|false
//|false
//|true
//|true
//|true
//|true
//|true
//|true
//|true
// END EXPECTED OUTPUT

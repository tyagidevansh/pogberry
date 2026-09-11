use "pb_gui" as gui;
use "std.math";

var BLOCK_SIZE = 100;
var GRID_WIDTH = 5;
var GRID_HEIGHT = 5;
var WINDOW_WIDTH = BLOCK_SIZE * GRID_WIDTH;
var WINDOW_HEIGHT = BLOCK_SIZE * GRID_HEIGHT + 60;

var moleX = 0;
var moleY = 0;
var hitX = 0;
var hitY = 0;
var hitTimer = 0.0;
var score = 0;

fun spawnMole() {
    var newX = moleX;
    var newY = moleY;
    if (GRID_WIDTH > 1 or GRID_HEIGHT > 1) {
        while (newX == moleX and newY == moleY) {
            newX = math.floor(rand() * GRID_WIDTH);
            newY = math.floor(rand() * GRID_HEIGHT);
        }
    }
    moleX = newX;
    moleY = newY;
}

fun handleClick() {
    if (gui.isMouseButtonPressed("LEFT")) {
        var mx = gui.getMouseX();
        var my = gui.getMouseY();

        var gx = math.floor(mx / BLOCK_SIZE);
        var gy = math.floor(my / BLOCK_SIZE);

        if (gx == moleX and gy == moleY) {
            score = score + 1;
            hitX = moleX;
            hitY = moleY;
            hitTimer = 0.25;
            spawnMole();
            return true;
        }
    }
    return false;
}

fun drawGame(timeLeft) {
    gui.beginDrawing();
    gui.clearBackground(34, 110, 48);

    // Lawn and hole tiles
    for (var y = 0; y < GRID_HEIGHT; y = y + 1) {
        for (var x = 0; x < GRID_WIDTH; x = x + 1) {
            var px = x * BLOCK_SIZE;
            var py = y * BLOCK_SIZE;

            // Grass patch
            gui.drawRectangle(px + 4, py + 4, BLOCK_SIZE - 8, BLOCK_SIZE - 8, 48, 135, 62);

            // Dirt mound & hole
            gui.drawCircle(px + 50, py + 55, 34.0, 55, 38, 24);
            gui.drawCircle(px + 50, py + 55, 30.0, 28, 18, 10);
        }
    }

    // Draw Mole
    var mx = moleX * BLOCK_SIZE + 50;
    var my = moleY * BLOCK_SIZE + 50;

    // Mole head
    gui.drawCircle(mx, my, 28.0, 130, 82, 45);
    // Ears
    gui.drawCircle(mx - 20, my - 16, 8.0, 115, 70, 38);
    gui.drawCircle(mx + 20, my - 16, 8.0, 115, 70, 38);
    gui.drawCircle(mx - 20, my - 16, 4.0, 190, 130, 110);
    gui.drawCircle(mx + 20, my - 16, 4.0, 190, 130, 110);
    // Eyes
    gui.drawCircle(mx - 9, my - 6, 4.0, 20, 20, 20);
    gui.drawCircle(mx + 9, my - 6, 4.0, 20, 20, 20);
    gui.drawCircle(mx - 8, my - 7, 1.5, 255, 255, 255);
    gui.drawCircle(mx + 10, my - 7, 1.5, 255, 255, 255);
    // Snout and nose
    gui.drawCircle(mx, my + 5, 8.0, 210, 150, 120);
    gui.drawCircle(mx, my + 3, 3.5, 35, 15, 15);

    // Whack popup effect
    if (hitTimer > 0.0) {
        var hx = hitX * BLOCK_SIZE + 18;
        var hy = hitY * BLOCK_SIZE + 12;
        gui.drawText("WHACK! +1", hx, hy, 16, 255, 235, 60);
    }

    // Bottom Status Bar
    gui.drawRectangle(0, BLOCK_SIZE * GRID_HEIGHT, WINDOW_WIDTH, 60, 22, 24, 30);
    gui.drawRectangle(0, BLOCK_SIZE * GRID_HEIGHT, WINDOW_WIDTH, 2, 0, 180, 220);

    gui.drawText("SCORE: " + str(score), 20, BLOCK_SIZE * GRID_HEIGHT + 18, 24, 255, 255, 255);

    var secondsLeft = math.floor(timeLeft + 0.999);
    if (secondsLeft <= 5) {
        gui.drawText("TIME: " + str(secondsLeft) + "s", 360, BLOCK_SIZE * GRID_HEIGHT + 18, 24, 255, 80, 80);
    } else {
        gui.drawText("TIME: " + str(secondsLeft) + "s", 360, BLOCK_SIZE * GRID_HEIGHT + 18, 24, 255, 220, 40);
    }

    gui.endDrawing();
}

fun drawGameOver() {
    gui.beginDrawing();
    gui.clearBackground(20, 20, 26);

    var title = "TIME'S UP!";
    var tw = gui.measureText(title, 36);
    gui.drawText(title, math.floor((WINDOW_WIDTH - tw) / 2), 130, 36, 255, 75, 75);

    var scoreStr = "FINAL SCORE: " + str(score);
    var sw = gui.measureText(scoreStr, 28);
    gui.drawText(scoreStr, math.floor((WINDOW_WIDTH - sw) / 2), 200, 28, 255, 230, 80);

    var prompt = "CLICK OR PRESS SPACE TO PLAY AGAIN";
    var pw = gui.measureText(prompt, 18);
    gui.drawText(prompt, math.floor((WINDOW_WIDTH - pw) / 2), 280, 18, 120, 230, 160);

    gui.endDrawing();
}

fun gameLoop() {
    spawnMole();
    score = 0;
    hitTimer = 0.0;
    var moleTimer = 0.0;
    var timeLeft = 30.0;

    while (!gui.windowShouldClose()) {
        var dt = gui.getFrameTime();
        if (dt > 0.05) dt = 0.05;

        timeLeft = timeLeft - dt;
        moleTimer = moleTimer + dt;
        if (hitTimer > 0.0) hitTimer = hitTimer - dt;

        if (timeLeft <= 0.0) {
            break;
        }

        // Mole hides faster as score increases (1.2s down to 0.65s)
        var maxMoleTime = 1.2 - (score * 0.02);
        if (maxMoleTime < 0.65) maxMoleTime = 0.65;

        if (moleTimer > maxMoleTime) {
            spawnMole();
            moleTimer = 0.0;
        }

        if (handleClick()) {
            moleTimer = 0.0;
        }

        drawGame(timeLeft);
    }
}

fun waitForRestart() {
    var debounceTimer = 0.4;
    while (!gui.windowShouldClose()) {
        var dt = gui.getFrameTime();
        if (debounceTimer > 0.0) {
            debounceTimer = debounceTimer - dt;
        }

        drawGameOver();

        if (debounceTimer <= 0.0) {
            if (gui.isMouseButtonPressed("LEFT") or gui.isKeyPressed("KEY_SPACE") or gui.isKeyPressed("KEY_ENTER")) {
                return;
            }
        }
    }
}

fun main() {
    gui.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Whack-a-Mole - Pogberry");
    gui.setVirtualResolution(WINDOW_WIDTH, WINDOW_HEIGHT);
    gui.setTargetFPS(60);

    while (!gui.windowShouldClose()) {
        gameLoop();
        if (gui.windowShouldClose()) {
            break;
        }
        waitForRestart();
    }

    gui.closeWindow();
}

main();

use "pb_gui" as gui;

var BLOCK_SIZE = 100;
var GRID_WIDTH = 5;
var GRID_HEIGHT = 5;
var WINDOW_HEIGHT = BLOCK_SIZE * GRID_HEIGHT + 50;

var moleX = 0;
var moleY = 0;
var score = 0;

fun spawnMole() {
    moleX = floor(rand() * GRID_WIDTH);
    moleY = floor(rand() * GRID_HEIGHT);
}

fun handleClick() {
    if (gui.isMouseButtonPressed("LEFT")) {
        var mx = gui.getMouseX();
        var my = gui.getMouseY();

        var gx = floor(mx / BLOCK_SIZE);
        var gy = floor(my / BLOCK_SIZE);

        if (gx == moleX and gy == moleY) {
            score = score + 1;
            spawnMole();
            return true;
        }
    }
    return false;
}

fun drawGame(timeLeft) {
    gui.beginDrawing();
    gui.clearBackground(30, 30, 30);

    for (var y = 0; y < GRID_HEIGHT; y = y + 1) {
        for (var x = 0; x < GRID_WIDTH; x = x + 1) {
            gui.drawRectangle(x * BLOCK_SIZE, y * BLOCK_SIZE, BLOCK_SIZE - 2, BLOCK_SIZE - 2, 100, 100, 100);
        }
    }

    gui.drawRectangle(moleX * BLOCK_SIZE, moleY * BLOCK_SIZE, BLOCK_SIZE - 2, BLOCK_SIZE - 2, 200, 50, 50);

    gui.drawText("Score: " + str(score), 10, BLOCK_SIZE * GRID_HEIGHT + 10, 24, 255, 255, 255);
    gui.drawText("Time: " + str(floor(timeLeft)), 400, BLOCK_SIZE * GRID_HEIGHT + 10, 24, 200, 200, 0);

    gui.endDrawing();
}

fun drawGameOver() {
    gui.beginDrawing();
    gui.clearBackground(20, 20, 20);

    gui.drawText("Time's Up!", 100, 100, 32, 255, 100, 100);
    gui.drawText("Final Score: " + str(score), 100, 150, 28, 255, 255, 255);
    gui.drawText("Click to Restart", 100, 200, 24, 100, 255, 100);

    gui.endDrawing();
}

fun gameLoop() {
    spawnMole();
    score = 0;
    var lastTime = getTime();
    var moleTimer = 0.0;
    var timeLeft = 5.0;

    while (!gui.windowShouldClose()) {
        var currentTime = getTime();
        var deltaTime = currentTime - lastTime;
        lastTime = currentTime;

        timeLeft = timeLeft - deltaTime;
        moleTimer = moleTimer + deltaTime;

        if (timeLeft <= 0) {
            break;
        }

        if (moleTimer > 1.5) {
            spawnMole();
            moleTimer = 0;
        }

        if (handleClick()) {
            moleTimer = 0;
        }

        drawGame(timeLeft);
    }
}

fun waitForRestart() {
    while (!gui.windowShouldClose()) {
        drawGameOver();
        if (gui.isMouseButtonPressed("LEFT")) {
            return;
        }
    }
}

fun main() {
    gui.initWindow(BLOCK_SIZE * GRID_WIDTH, WINDOW_HEIGHT, "Whack-a-Mole");
    gui.setTargetFPS(60);

    while (!gui.windowShouldClose()) {
        gameLoop();
        waitForRestart();
    }
}

main();

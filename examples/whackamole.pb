use "pogberry_gui";

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
    if (isMouseButtonPressed("LEFT")) {
        var mx = getMouseX();
        var my = getMouseY();

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
    beginDrawing();
    clearBackground(30, 30, 30);

    for (var y = 0; y < GRID_HEIGHT; y = y + 1) {
        for (var x = 0; x < GRID_WIDTH; x = x + 1) {
            drawRectangle(x * BLOCK_SIZE, y * BLOCK_SIZE, BLOCK_SIZE - 2, BLOCK_SIZE - 2, 100, 100, 100);
        }
    }

    drawRectangle(moleX * BLOCK_SIZE, moleY * BLOCK_SIZE, BLOCK_SIZE - 2, BLOCK_SIZE - 2, 200, 50, 50);

    drawText("Score: " + score, 10, BLOCK_SIZE * GRID_HEIGHT + 10, 24, 255, 255, 255);
    drawText("Time: " + floor(timeLeft), 400, BLOCK_SIZE * GRID_HEIGHT + 10, 24, 200, 200, 0);

    endDrawing();
}

fun drawGameOver() {
    beginDrawing();
    clearBackground(20, 20, 20);

    drawText("Time's Up!", 100, 100, 32, 255, 100, 100);
    drawText("Final Score: " + score, 100, 150, 28, 255, 255, 255);
    drawText("Click to Restart", 100, 200, 24, 100, 255, 100);

    endDrawing();
}

fun gameLoop() {
    spawnMole();
    score = 0;
    var lastTime = getTime();
    var moleTimer = 0.0;
    var timeLeft = 5.0;

    while (!windowShouldClose()) {
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
    while (!windowShouldClose()) {
        drawGameOver();
        if (isMouseButtonPressed("LEFT")) {
            return;
        }
    }
}

fun main() {
    initWindow(BLOCK_SIZE * GRID_WIDTH, WINDOW_HEIGHT, "Whack-a-Mole");
    setTargetFPS(60);

    while (!windowShouldClose()) {
        gameLoop();
        waitForRestart();
    }
}

main();

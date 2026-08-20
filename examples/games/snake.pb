use "pb_gui" as gui;
use "std.math";

var BLOCK_SIZE = 20;
var GRID_WIDTH = 40;
var GRID_HEIGHT = 30;

var snake;
var dir;
var nextDir;
var fruit;
var isDead = false;
var deathTimer = 0.0;

fun resetGame() {
    snake = [[5, 5]];
    dir = [1, 0];
    nextDir = [1, 0];
    spawnFruit();
    isDead = false;
    deathTimer = 0.0;
}

fun spawnFruit() {
    var placed = false;
    while (!placed) {
        var fx = math.floor(rand() * GRID_WIDTH);
        var fy = math.floor(rand() * GRID_HEIGHT);
        var valid = true;
        var i = 0;

        while (i < len(snake)) {
            var p = snake[i];
            if (p[0] == fx and p[1] == fy) {
                valid = false;
            }
            i = i + 1;
        }

        if (valid) {
            fruit = [fx, fy];
            placed = true;
        }
    }
}

fun updateInput() {
    if (gui.isKeyPressed("KEY_UP") and dir[1] != 1) {
        nextDir = [0, -1];
    } else if (gui.isKeyPressed("KEY_DOWN") and dir[1] != -1) {
        nextDir = [0, 1];
    } else if (gui.isKeyPressed("KEY_LEFT") and dir[0] != 1) {
        nextDir = [-1, 0];
    } else if (gui.isKeyPressed("KEY_RIGHT") and dir[0] != -1) {
        nextDir = [1, 0];
    }
}

fun updateSnake() {
    dir = nextDir;

    var head = snake[0];
    var newX = head[0] + dir[0];
    var newY = head[1] + dir[1];

    // Wrap around screen
    if (newX < 0) newX = GRID_WIDTH - 1;
    if (newY < 0) newY = GRID_HEIGHT - 1;
    if (newX >= GRID_WIDTH) newX = 0;
    if (newY >= GRID_HEIGHT) newY = 0;

    var newHead = [newX, newY];

    // Check self-collision
    var collided = false;
    var i = 0;
    while (i < len(snake)) {
        var p = snake[i];
        if (p[0] == newX and p[1] == newY) {
            collided = true;
        }
        i = i + 1;
    }

    if (collided) {
        isDead = true;
        return;
    }

    snake.insert(0, newHead); // insert at front

    // Check fruit collision
    if (newX == fruit[0] and newY == fruit[1]) {
        spawnFruit(); // grow
    } else {
        snake.pop(); // move (remove tail)
    }
}

fun drawGame() {
    gui.beginDrawing();
    gui.clearBackground(20, 20, 20);

    // Draw snake
    var i = 0;
    while (i < len(snake)) {
        var point = snake[i];
        gui.drawRectangle(point[0] * BLOCK_SIZE, point[1] * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE, 255, 255, 255);
        i = i + 1;
    }

    // Draw fruit
    gui.drawRectangle(fruit[0] * BLOCK_SIZE, fruit[1] * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE, 255, 0, 0);

    gui.endDrawing();
}

fun main() {
    gui.initWindow(BLOCK_SIZE * GRID_WIDTH, BLOCK_SIZE * GRID_HEIGHT, "Snake");

    var lastTime = getTime();
    resetGame();

    while (!gui.windowShouldClose()) {
        var now = getTime();

        updateInput();

        if (!isDead and now - lastTime >= 0.1) {
            updateSnake();
            lastTime = now;
        }

        if (isDead) {
            deathTimer = deathTimer + (now - lastTime);
            if (deathTimer >= 1.0) {
                resetGame();
                lastTime = now;
            }
        }

        drawGame();
    }
}

main();

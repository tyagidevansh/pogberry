use "pogberry_gui";

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
        var fx = floor(rand() * GRID_WIDTH);
        var fy = floor(rand() * GRID_HEIGHT);
        var valid = true;
        var i = 0;

        while (i < snake.size()) {
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
    if (isKeyPressed("KEY_UP") and dir[1] != 1) {
        nextDir = [0, -1];
    } else if (isKeyPressed("KEY_DOWN") and dir[1] != -1) {
        nextDir = [0, 1];
    } else if (isKeyPressed("KEY_LEFT") and dir[0] != 1) {
        nextDir = [-1, 0];
    } else if (isKeyPressed("KEY_RIGHT") and dir[0] != -1) {
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
    while (i < snake.size()) {
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

    snake.add(newHead, 0); // insert at front

    // Check fruit collision
    if (newX == fruit[0] and newY == fruit[1]) {
        spawnFruit(); // grow
    } else {
        snake.pop(); // move (remove tail)
    }
}

fun drawGame() {
    beginDrawing();
    clearBackground(20, 20, 20);

    // Draw snake
    var i = 0;
    while (i < snake.size()) {
        var point = snake[i];
        drawRectangle(point[0] * BLOCK_SIZE, point[1] * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE, 255, 255, 255);
        i = i + 1;
    }

    // Draw fruit
    drawRectangle(fruit[0] * BLOCK_SIZE, fruit[1] * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE, 255, 0, 0);

    endDrawing();
}

fun main() {
    initWindow(BLOCK_SIZE * GRID_WIDTH, BLOCK_SIZE * GRID_HEIGHT, "Snake");

    var lastTime = getTime();
    resetGame();

    while (!windowShouldClose()) {
        var now = getTime();

        updateInput();

        if (!isDead and now - lastTime >= 0.2) {
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

use "pogberry_gui";

var BLOCK_SIZE = 20;
var GRID_HEIGHT = 30;
var GRID_WIDTH = 40;

fun main() {
    initWindow(BLOCK_SIZE * GRID_WIDTH, BLOCK_SIZE * GRID_HEIGHT, "Snake");

    while (!windowShouldClose()) {
        beginDrawing();
        clearBackground(20, 20, 20);
        endDrawing();
    }
}

main();
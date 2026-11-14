# Examples

- `basics` contains small syntax and standard-library examples.
- `algorithms` contains data-structure and algorithm exercises.
- `games` contains GUI examples:
  - `f1_25`: PB Sports F1 25, a 3D Formula 1 arcade racing game with circuits, car models, cameras, rivals, and a track editor.
  - `space_combat.pb`: arcade space combat game with thrusters, shields, asteroids, particles, live radar, and Raylib collision detection.
  - `raylib_showcase.pb`: interactive visual demonstration of extended 2D drawing primitives, gradients, animations, and collision queries.
  - `snake.pb`, `whack_a_mole.pb`, `click_the_square.pb`, and the multi-file `gui_project`.
- `module_project` is an interactive multi-file terminal adventure.

Run an example from the repository root:

```sh
pb run examples/basics/fizzbuzz.pb
pb run examples/games/f1_25
pb run examples/games/space_combat.pb
pb run examples/games/raylib_showcase.pb
pb run examples/games/gui_project
```

Run `make` and `make install PREFIX="$HOME/.local"` from the repository root
first. Without installing, replace `pb` with `build/pb`.

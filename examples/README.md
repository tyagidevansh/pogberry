# Examples

- `basics` contains small syntax and standard-library examples.
- `algorithms` contains data-structure and algorithm exercises.
- `games` contains GUI examples, including the multi-file `gui_project`.
- `module_project` is an interactive multi-file terminal adventure.

Run an example from the repository root:

```sh
pb run examples/basics/fizzbuzz.pb
pb run examples/module_project
pb run examples/games/gui_project
```

Run `make` and `make install PREFIX="$HOME/.local"` from the repository root
first. Without installing, replace `pb` with `build/pb`.

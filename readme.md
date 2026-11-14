# Pogberry

Pogberry is a lightweight, bytecode-compiled programming language designed for learning, scripting, and building standalone 2D and 3D games. It pairs an approachable, readable syntax with a fast C interpreter and an embeddable runtime. The command-line executable and C embedding API use the short name `pb`.

The project is under active development. The core language, collections, classes, source modules, native modules, embedding API, test suite, and 2D and 3D game engine work today.

## Build and install

### Linux / macOS

Build the interpreter and install it for your user:

```sh
make
make install PREFIX="$HOME/.local"
```

This installs `pb`, its GUI runtime (`lib/pb_raylib_linux.so`), and standard-library sources under `~/.local`. If `~/.local/bin` is on `PATH`, `pb` can then be used from any directory. Use `sudo make install` for an all-users installation under `/usr/local`.

### Windows

Ensure `gcc` and `make` are installed and available in your terminal.

Run `make` from the repository root:
```cmd
make
```

To run `pb` from any directory, copy the binary, standard library, and runtime libraries to a folder on your `PATH` (such as `%LOCALAPPDATA%\Programs\pogberry`):

---

## Running programs

Run the `main.pb` in a project directory:

```sh
pb run examples/module_project
```

From inside a project, the path can be omitted:

```sh
pb run
```

You can also run a specific source file or start the REPL:

```sh
pb run examples/basics/hello_world.pb
pb repl
```

Without installing, commands can be run directly from the repository root:
- On Linux or macOS: `./build/pb run examples/games/f1_25`
- On Windows: `build\pb run examples\games\f1_25`

Build the embeddable shared library:

```sh
make shared
```

Run every test:

```sh
make test
```

## Examples

The [examples](examples/README.md) directory is organized by purpose:

- `examples/basics` contains small language examples.
- `examples/algorithms` contains algorithms and data structures.
- `examples/games` contains 2D and 3D games, including PB Sports F1 25.
- `examples/module_project` contains an interactive multi-file terminal game.

```sh
pb run examples/module_project
pb run examples/games/f1_25
```

For 3D game development, see the PB Sports F1 25 guide in `examples/games/f1_25/README.md`.

## Language basics

Statements end with semicolons. `//` starts a line comment.

```pb
let name = "Sajid";
let health = 100;
health -= 10;

if (health > 0)
  print(name + " is still standing.");
```

`let` creates a mutable binding. Compound assignment operators (`+=`, `-=`, `*=`, `/=`, `%=`) are supported for variables, object properties, list indices, and map keys:

```pb
let count = 10;
count += 5;             // 15
count *= 2;             // 30

player.x += speed * dt; // object properties
inventory[0] -= 1;      // lists
stats["score"] += 100;  // maps
name += "!";            // string concatenation
```

Values include `nil`, booleans, numbers, strings, lists, maps, functions, classes, instances, and
modules. `false` and `nil` are falsey; every other value is truthy.

Numbers use double precision. Division and modulo by zero are runtime errors.
Modulo and collection indexes require finite integers.

Strings support `\\`, `\"`, `\n`, `\r`, and `\t` escapes. Strings compare by
content and can be indexed:

```pb
let word = "Pogberry";
print(word[0]);
print("Score: " + str(12));
```

String concatenation requires two strings. Use `str(value)` for explicit
conversion.

## Functions and control flow

Pogberry supports `if`, `else`, `while`, `for`, `break`, and `continue`.

```pb
fun factorial(number)
{
  if (number == 0)
    return 1;
  return number * factorial(number - 1);
}

for (let i = 0; i < 5; i += 1)
  print(factorial(i));
```

Functions are first-class values, support recursion, and capture surrounding
locals as closures.

```pb
fun makeCounter()
{
  let value = 0;
  fun next()
  {
    value = value + 1;
    return value;
  }
  return next;
}
```

## Input and output

`print` writes a value and normally adds a newline:

```pb
print("Loading", newline=false);
print("...");
```

`strInput()` reads a line. It accepts an optional prompt and returns `nil` when
input closes:

```pb
let name = strInput("Name: ");
if (name != nil)
  print("Hello, " + name + ".");
```

## Lists

Lists are mutable, structurally comparable, and support negative indexes.

```pb
let values = [3, 1, 2];
values.push(4);
values[0] = 5;
values.sort();
print(values);
print(values[-1]);
```

Available list methods:

- `push(value)`
- `extend(list)`
- `pop()` and `pop(index)`
- `insert(index, value)`
- `remove(value)`
- `removeAt(index)`
- `clear()`
- `copy()`
- `index(value)`
- `count(value)`
- `reverse()`
- `sort()` for lists containing only numbers or only strings

Use `len(list)` for its length.

## Maps

Maps are mutable, structurally comparable, and retain insertion order.

```pb
let player = {"name": "Mira", "health": 100};
player["health"] = 85;

if (player.has("health"))
  print(player.get("health", 0));
```

Map keys may be `nil`, booleans, finite numbers, or strings. Available methods
and properties are:

- `has(key)`
- `get(key, defaultValue)`
- `delete(key)`
- `clear()`
- `length`

`len(map)` also returns its length. Recursive lists and maps render safely;
unsupported recursive equality reports a runtime error instead of overflowing
the process stack.

## Classes

Classes support dynamic fields, methods, constructors, single inheritance,
`this`, `super`, and bound methods.

```pb
class Actor
{
  init(name)
  {
    this.name = name;
  }

  describe()
  {
    print(this.name);
  }
}

class Enemy < Actor
{
  describe()
  {
    super.describe();
    print("Enemy");
  }
}

let enemy = Enemy("Slime");
let describe = enemy.describe;
describe();
```

## Modules and multi-file projects

Each project has an entry file. The `pb` CLI resolves source modules relative
to that entry file's directory.

```text
game/
├── main.pb
├── player.pb
└── combat.pb
```

`player.pb` can export declarations:

```pb
export let startingHealth = 100;

export class Player
{
  init(name)
  {
    this.name = name;
    this.health = startingHealth;
  }
}
```

`main.pb` imports the module:

```pb
use "player";

let hero = player.Player("Mira");
print(hero.health);
```

`as` is optional. The default alias is the final component of the module name:

```pb
use "player";                  // player
use "game/combat";             // combat
use "std.math";                // math
use "game/combat" as battle;   // battle
```

If the derived component is not a valid identifier, an explicit alias is
required. Imports are top-level only. A source module has isolated globals,
only exposes declarations marked `export`, executes once per VM, and is then
cached. Circular imports are reported as load errors.

The CLI maps `"player"` to `player.pb` and `"game/combat"` to
`game/combat.pb`. Absolute paths, backslashes, empty path components, `.` and
`..` components are rejected. Host-provided module names are reserved and take
precedence over project files.

Standard-library modules use the reserved `std.` namespace and load from the
standard library shipped beside `pb`, so project files cannot replace them.
`std.math` is implemented as a normal Pogberry source module:

```pb
use "std.math";

print(math.pi);
print(math.sqrt(81));
print(math.clamp(14, 0, 10));
```

It exports `pi`, `e`, `abs`, `floor`, `sqrt`, `min`, `max`, and `clamp`.
`abs` and the helpers are Pogberry code. Only `floor` and `sqrt` delegate to
the host's internal `pb.math` capability.

## 2D and 3D game development with pb_gui

Pogberry includes a graphics module powered by Raylib. It supports both 2D and 3D rendering in the same window.

### 2D rendering example

```pb
use "pb_gui" as gui;

gui.initWindow(800, 600, "2D Example");
gui.setTargetFPS(60);

while (!gui.windowShouldClose())
{
  gui.beginDrawing();
  gui.clearBackground(20, 20, 30);
  gui.drawText("Hello Pogberry!", 20, 20, 24, 255, 255, 255);
  gui.endDrawing();
}

gui.closeWindow();
```

### 3D rendering example

3D drawing runs inside a `begin3D` and `end3D` block. You can draw 3D shapes or load 3D models from disk, then draw 2D text or interface elements on top:

```pb
use "pb_gui" as gui;

gui.initWindow(1280, 720, "3D Example");
gui.setTargetFPS(60);

while (!gui.windowShouldClose())
{
  gui.beginDrawing();
  gui.clearBackground(24, 28, 36);

  // Camera: eye X, Y, Z, target X, Y, Z, fov
  gui.begin3D(0.0, 5.0, 10.0, 0.0, 0.0, 0.0, 45.0);
  gui.drawGrid(20, 1.0);
  gui.drawPlane3D(0.0, 0.0, 0.0, 20.0, 20.0, 40, 45, 55);
  gui.drawCubeWires3D(0.0, 1.0, 0.0, 2.0, 2.0, 2.0, 60, 220, 240);
  gui.end3D();

  // 2D interface pass
  gui.drawText("3D in Pogberry", 20, 20, 24, 255, 255, 255);
  gui.endDrawing();
}

gui.closeWindow();
```

The module provides functions for 2D and 3D games:
- Window control with resizing, fullscreen toggles, window titles, target frame rates, and frame time measurement.
- 2D shapes such as lines, circles, outlines, ellipses, and rectangles.
- 3D camera passes using `begin3D` or `begin3DEx`, closed with `end3D`.
- 3D shapes such as cubes, planes, spheres, cylinders, triangles, and quads.
- 3D model loading for OBJ and GLB files with `loadModel`, drawing with `drawModel` or `drawModelEx`, and memory release with `unloadModel`.
- Text rendering and text measurement for layout alignment.
- Keyboard, mouse, cursor position, and scroll wheel input queries.
- 2D collision detection between rectangles, circles, and points.
- Sprites and textures with image loading, spritesheet rendering via `drawTextureRec`, and render textures.
- Fragment shader loading and custom uniform updates.
- Audio playback with `loadSound` for effects and `loadMusic` for streaming tracks.

For a full 3D game implementation, see `examples/games/f1_25`. It includes procedural road generation, multi-camera chase views, rivals, collision physics, and audio.

## Prelude functions

These functions are currently available without an import:

- `clock()` and `getTime()`
- `rand()` and `rand(positiveIntegerBound)`
- `strInput()` and `strInput(prompt)`
- `len(stringOrCollection)`
- `type(value)`
- `str(value)`

Invalid arguments produce normal runtime errors and stack traces.

## Error behavior

The interpreter reports compile errors, runtime errors, module source names,
and call stacks without terminating the host process. Checked failures include
wrong function arity, stack overflow, invalid collection indexes, invalid map
keys, missing exports, read-only module exports, division by zero, modulo
errors, and invalid native arguments.

CLI exit statuses are:

- `64` for invalid command-line usage
- `65` for a compile error
- `70` for a runtime error
- `74` when the entry file cannot be read

## Embedding API

The public header is [`src/headers/pb.h`](src/headers/pb.h). A host can:

- create and destroy independent `PbVM` instances;
- interpret source;
- call script functions;
- register global native functions;
- register native modules;
- register source modules;
- resolve modules lazily;
- receive output and structured diagnostic callbacks;
- exchange nil, booleans, numbers, strings, and VM-owned objects.

The shared library is `build/libpb.so` on Linux and `build/pb.dll` on Windows.
The host API uses the `Pb` and `pb` prefixes.

## Implementation

Source passes through a scanner and a single-pass Pratt compiler into bytecode.
The VM executes that bytecode with lexical closures, per-VM globals, module
namespaces, native callbacks, interned strings, and garbage-collected objects.

The CLI owns filesystem and built-in module resolution under `src/host`. Its
host modules provide the current GUI adapter and internal math capability;
neither is linked into the shared VM. The language core does not know about
project paths or `pb_gui`, which keeps it reusable by the editor and other
embedding hosts.

See [`language-spec.md`](language-spec.md) for the target language design and
[`tests/README.md`](tests/README.md) for the test runner.

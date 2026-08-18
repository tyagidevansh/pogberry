# Pogberry Language Specification

**Status:** Ready for Pogberry 2.0  
**Scope:** This is the target specification. It intentionally differs from the
current interpreter where the current behaviour is unsafe, incomplete, or an
implementation accident. It also contains all the extra features I plan on 
adding to the language over the next month. Changes in this spec likely.

## 1. Purpose and design position

Pogberry is an dynamically typed scripting language for games and
interactive simulations. It is designed to be easy to pick up and more 
approachable than general-purpose programming languages.
While the syntax is fairly pythonic, the hope is that by baking 
in all the GUI stuff rather than having the user rely on external libraries, 
Pogberry would be a simpler to learn and use. A middle ground in between 
scratch and python + pygame.

Pogberry is **not** a wrapper around Raylib. A Raylib binding is going to be the first
and best-supported host adapter, but Raylib is not part of the language, its
syntax, or its core standard library. A script written against the core and a
documented `engine.*` module surface should be portable to another host that
implements that surface.

The language has four layers:

1. **Core language** - syntax, values, functions, classes, collections, and
   errors. Every conforming implementation provides this layer.
2. **Core standard library** - deterministic utilities for strings, lists,
   maps, math, and logging.
3. **Host interface** - a C-facing API through which an application creates a
   VM, supplies modules, invokes exports, and receives diagnostics.
4. **Engine adapter** - optional modules such as `engine.graphics`,
   `engine.input`, and `engine.audio`. Raylib is one possible adapter.

### 1.1 Goals

- Small, readable syntax with lexical scope and closures.
- No process crash, invalid memory access, or VM-stack corruption caused by
  script input.
- Predictable collection behaviour and deterministic iteration order.
- A capability-based host boundary: scripts can only use engine features that
  their host explicitly exposes.
- Stable public semantics. Optimisations such as string interning and garbage
  collection are never observable language behaviour.
- A graphics API, physics engine, editor, and import semantics.
- Built-in, sandboxed access to game assets and save data.

### 1.2 Non-goals for 2.0
- A JIT compiler.
- Static typing or a type annotation system.
- Supporting writing the interpreter in Pogberry

## 2. Source text and lexical rules

Version 2.0 identifiers use ASCII letters, digits, and `_`, beginning with  a 
letter or `_`. For now only UTF-8 but Unicode identifiers may be added later 
without changing the rest of the grammar.

- Whitespace separates tokens and is otherwise insignificant.
- `//` begins a line comment.
- Block comments are not supported.
- Statements end with `;`. Automatic semicolon insertion is not part of 2.0.
- Strings use double quotes. The required escapes are `\\`, `\"`, `\n`, `\r`,
  and `\t`; unknown escapes are compile errors.
- Numbers are IEEE-754 double-precision values. Decimal literals are required;
  hexadecimal, binary, and numeric separators are not supported for now.

Reserved words are: `and`, `as`, `break`, `class`, `const`, `continue`,
`else`, `export`, `false`, `for`, `fun`, `if`, `let`, `nil`, `or`, `return`,
`super`, `this`, `true`, `use`, `var`, and `while`.

`let` is introduced in 2.0. `var` remains a supported mutable-declaration
spelling; new code should prefer `let` for consistency with `const`.

## 3. Values, identity, and mutability

Every runtime value is one of the following:

| Kind | Mutable | Equality |
|---|---:|---|
| `nil` | no | equal to `nil` only |
| Boolean | no | by value |
| Number | no | IEEE numeric equality |
| String | no | by Unicode byte sequence |
| List | yes | element by element |
| Map | yes | key/value by key/value |
| Function | no | identity |
| Class | no after declaration | identity |
| Instance | yes | identity |
| Host object | host-defined | identity unless its module specifies otherwise |

Strings are immutable. An implementation may intern strings, copy them, or
compact them in memory, but scripts must not be able to observe that choice.
In particular, no library operation may modify a string's contents in place. 
Existing implementation does not respect this and needs to be fixed.

Lists, maps, and instances are reference values. Assigning one copies the
reference, not its contents. There is no implicit deep copy.

Equality deliberately follows Python's collection rules:

- Two Lists are equal when they have the same length and each corresponding
  element is equal. List order matters.
- Two Maps are equal when they have the same set of keys and the value for
  every key is equal. Map insertion order does not affect equality.
- Lists and Maps are mutable and therefore are not valid Map keys.

An implementation must first return true when comparing a container to itself.
Comparison of two distinct recursive containers follows the implementation's
normal recursion limit and raises a runtime error if that limit is exceeded,
as Python does for unsupported recursive comparisons.

`false` and `nil` are falsey. Every other value, including `0`, `""`, empty
lists, and empty maps, is truthy.

### 3.1 Numbers

Arithmetic uses double precision. Division or modulo by zero is a runtime
error. Modulo requires finite integral operands and returns an integral Number.
An index must be a finite integral Number; converting `1.9` to index `1` is
not permitted.

`NaN` follows IEEE comparison rules and is not a valid Map key. Hosts that
need deterministic simulations should provide a fixed-step clock and a seeded
random-number object instead of relying on host time or implicit global random
state.

### 3.2 Strings

String concatenation is defined for two strings. The standard library provides
explicit conversion, for example `string.from(value)`. The `+` operator must
not silently turn an arbitrary object into `"NaN"` or another placeholder.

String indexing is deliberately absent from the core because byte indexing is
incorrect for UTF-8 text. The `string` module provides code-point-aware
operations. A future byte-string type may have separate indexing semantics.

## 4. Declarations, scope, and functions

Pogberry has lexical scope. A declaration is visible from its initializer's
completion to the end of its enclosing block or module.

```pogberry
let health = 100;
const maxHealth = 100;

fun clampHealth(value) {
  return math.clamp(value, 0, maxHealth);
}
```

`let` bindings may be reassigned. `const` bindings may not be reassigned,
though the object referenced by a `const` may still be mutable.

Functions are first-class values. They close over variables from their lexical
environment, support recursion, and may be passed or returned normally.

```pogberry
fun makeCounter() {
  let value = 0;
  fun next() {
    value = value + 1;
    return value;
  }
  return next;
}
```

Function arguments are positional. Passing the wrong number of arguments is a
runtime error unless a future version adds explicit optional or variadic
parameters. There is no implementation-defined limit on local variables,
constants, or arguments in the language specification; an implementation that
has a practical limit must report a normal compile error.

## 5. Statements and control flow

```ebnf
program        = { declaration } EOF ;
declaration    = importDecl | exportDecl | classDecl | funDecl | varDecl | statement ;
importDecl     = "use" STRING [ "as" IDENTIFIER ] ";" ;
exportDecl     = "export" (classDecl | funDecl | varDecl) ;
classDecl      = "class" IDENTIFIER [ "<" IDENTIFIER ] "{" { method } "}" ;
funDecl        = "fun" IDENTIFIER functionBody ;
varDecl        = ( "let" | "var" | "const" ) IDENTIFIER [ "=" expression ] ";" ;
statement      = exprStmt | block | ifStmt | whileStmt | forStmt |
                 breakStmt | continueStmt | returnStmt ;
block          = "{" { declaration } "}" ;
ifStmt         = "if" "(" expression ")" statement [ "else" statement ] ;
whileStmt      = "while" "(" expression ")" statement ;
forStmt        = "for" "(" (varDecl | exprStmt | ";")
                 [ expression ] ";" [ expression ] ")" statement ;
breakStmt      = "break" ";" ;
continueStmt   = "continue" ";" ;
returnStmt     = "return" [ expression ] ";" ;
exprStmt       = expression ";" ;
```

`break` and `continue` are valid only inside a loop. They discard all locals
created after entry to that loop before transferring control. `return` exits
the current function and likewise releases its activation state.

Top-level `return`, `break`, and `continue` are compile errors.

## 6. Expressions

The required expression forms are literals, variables, assignment, grouping,
unary `!` and `-`, binary arithmetic/comparison/equality operators, `and`,
`or`, calls, property access, indexing, list literals, and map literals.

Operator precedence, highest to lowest, is:

1. calls, property access, indexing: `()`, `.`, `[]`
2. unary: `!`, `-`
3. multiplicative: `*`, `/`, `%`
4. additive: `+`, `-`
5. comparison: `<`, `<=`, `>`, `>=`
6. equality: `==`, `!=`
7. logical `and`
8. logical `or`
9. assignment: `=`

`and` and `or` short-circuit and return one of their operands. Assignment is
right-associative and evaluates to the assigned value. Valid targets are a
mutable binding, an instance field, a list element, or a map entry.

```pogberry
player.position.x = player.position.x + speed * dt;
inventory[slot] = item;
```

The compiler must compile every indexing operation directly. It must not infer
an arbitrary chain of indexes by inspecting the VM stack.

## 7. Lists and maps

### 7.1 Lists

Lists are ordered mutable sequences:

```pogberry
let enemies = ["slime", "bat"];
enemies.push("golem");
let first = enemies.removeAt(0);
```

List operations follow Python's familiar behaviour. `list[index]` reads an
element; `list[index] = value` replaces one. Positive indexes start at zero;
negative indexes count from the end, so `list[-1]` is the final element. A read
or replacement outside the list is a runtime error.

The following native methods are part of the standard library and are resolved
through ordinary runtime property lookup, not special parser rules:

- `list.push(value) -> nil`
- `list.extend(otherList) -> nil`
- `list.pop() -> value` and `list.pop(index) -> value` (error for an empty
  list or an invalid index)
- `list.insert(index, value) -> nil`; indexes are normalized and clamped to
  the valid insertion range, matching Python's `list.insert`.
- `list.remove(value) -> nil`; removes the first equal value and errors if it
  is absent.
- `list.removeAt(index) -> value`
- `list.clear() -> nil`
- `list.copy() -> List` (shallow copy)
- `list.index(value) -> Number` (error if absent)
- `list.count(value) -> Number`
- `list.reverse() -> nil`

`len(list)` returns a List's length. Slicing syntax and custom comparison
functions are deferred; they must not be added as compiler-only special cases.

Sorting is a List operation, never a mutation of text. `list.sort()` sorts a
list of all Numbers or all Strings in ascending order. Mixed or unsupported
values are a runtime error. A later release may add a custom comparison
function once its closure and error semantics are proven.

### 7.2 Maps

Maps are ordered mutable key-value collections:

```pogberry
let stats = { "hp": 100, "dead": false };
stats["hp"] = 85;
if (stats.has("hp")) print(stats["hp"]);
```

Permitted Map keys are `nil`, Boolean, finite non-NaN Number, and String.
Lists, maps, functions, classes, instances, and host objects are not Map keys
in 2.0. This rule keeps hashing stable and makes key semantics explicit.

Maps preserve insertion order. Updating an existing key does not change its
position; deleting and reinserting one places it at the end. This makes script
behaviour reproducible and allows a future iterator API.

- `map[key]` returns its value or `nil` when absent.
- `map[key] = value` inserts or replaces a value.
- `map.has(key) -> Boolean`
- `map.get(key, defaultValue) -> value`
- `map.delete(key) -> Boolean`
- `map.clear() -> nil`
- `map.length -> Number`

## 8. Classes and instances

Pogberry uses single-inheritance classes with dynamic instance fields.

```pogberry
class Actor {
  init(name) {
    this.name = name;
  }

  update(dt) {}
}

class Enemy < Actor {
  init(name, damage) {
    super.init(name);
    this.damage = damage;
  }
}
```

Calling a class creates an instance. If `init` exists, it is called with the
constructor arguments and always returns the new instance; returning another
value from `init` is a compile error. `this` is available only in methods.
`super` is available only in a subclass method and resolves the immediate
superclass method while preserving the current receiver.

Methods are functions and therefore support closures. A method extracted from
an instance remains bound to that instance:

```pogberry
let update = enemy.update;
update(dt);
```

Classes have no syntax for adding methods after declaration in 2.0. Instances
may receive dynamic data fields; reading an absent field is a runtime error.

## 9. Modules and the host boundary

Modules are named capabilities. Importing a module does not load a native
library from script code; it asks the host's module resolver for an already
registered module.

```pogberry
use "engine.graphics";
use "engine.input";
use "std.math";
```

`as` is optional. Without it, the final `/`- or `.`-separated component is
the alias, so the imports above bind `graphics`, `input`, and `math`.
An explicit alias is required when that component is not a valid identifier.

Imports are top-level only. A module has its own global scope and is evaluated
once per VM; subsequent imports receive the cached exports. Circular imports
are a compile/load error in 2.0. User modules expose names with `export`:

```pogberry
export fun spawnWave(level) {}
export const version = 1;
```

The `pb` CLI resolves source modules relative to the entry file. The name
`"player"` resolves to `player.pb`, while `"game/rules"` resolves to
`game/rules.pb`. Module names cannot be absolute or contain `.` or `..` path
segments. Host-provided module names are resolved before project files and
cannot be shadowed by them.

A host must provide a module resolver, module source or native exports, and a
stable module identifier. The core language provides no `dlopen`, shell,
socket, or reflection primitive. This is both a portability rule and an
important safety boundary. File access is provided through the sandboxed
asset/storage API below, not through arbitrary native calls.

### 9.1 Engine modules

The optional cross-engine module surface is intentionally small:

- `engine.app`: lifecycle and application metadata.
- `engine.input`: actions, pointer state, and device events.
- `engine.graphics`: drawing and resource handles.
- `engine.audio`: playback and resource handles.
- `engine.physics`: optional physics queries and bodies.
- `engine.storage`: optional sandboxed persistence.

An engine adapter may expose more modules under its own namespace, for example
`raylib.debug`, but portable games should depend only on documented
`engine.*` APIs. A host that has no graphics implementation simply does not
register `engine.graphics`.

Native APIs must validate every argument and return a normal Pogberry runtime
error on misuse. They must not print ad-hoc errors, dereference null function
pointers, or terminate the host process.

### 9.2 Script lifecycle

Games should be host-driven, not scripts that own the platform event loop. A
game module may export these optional functions:

```pogberry
export fun init() {}
export fun fixedUpdate(step) {}
export fun update(dt) {}
export fun draw() {}
export fun shutdown() {}
```

The host calls them in that order according to its own event loop. `fixedUpdate`
is for deterministic simulation; `update` and `draw` may be frame-rate
dependent. The host owns window creation, presentation, input polling, and
resource teardown. Raylib can implement this lifecycle cleanly without being
mentioned in a script.

Host objects are opaque, VM-owned references with host-supplied finalization.
Using a released host object is a runtime error. Engine resources should not be
represented as raw C pointers or integer addresses in scripts.

### 9.3 Assets and filesystem access

Loading assets is a core game-scripting requirement, so every full Pogberry
host provides these prelude objects without an import:

```pogberry
let dialogue = assets.readText("dialogue/intro.txt");
let imageData = assets.readBytes("sprites/player.png");
storage.writeText("saves/slot-1.json", saveData);
```

`assets` is read-only and rooted at the game's packaged asset directory.
`storage` is read/write and rooted at a host-selected per-game save directory.
Paths are relative UTF-8 paths; `..`, absolute paths, and paths escaping a
configured root are runtime errors. Hosts may package assets in an archive or
serve them through a platform API, so scripts must use this interface rather
than assume an operating-system path.

Required operations are `readText(path)`, `readBytes(path)`, and `exists(path)`
on `assets`; and `readText(path)`, `readBytes(path)`, `writeText(path, value)`,
`writeBytes(path, value)`, and `exists(path)` on `storage`. Missing files and
failed writes are host errors. A broader developer-only `fs` capability may be
registered explicitly, but it is not available to ordinary packaged games.

## 10. Errors and diagnostics

There are three result classes:

- **Compile error:** invalid source; no part of that module executes.
- **Runtime error:** invalid operation during execution; the current entrypoint
  stops and the host receives a failure result plus a stack trace.
- **Host error:** a module, asset, or platform operation failed; it is surfaced
  as a normal runtime error with host context.

An error must leave the VM in a valid reusable state. There is exactly one
runtime-error reporting path, shared by bytecode operations and native
functions. A diagnostic includes source identifier, line, column, message, and
a function stack trace where available.

`try`/`catch` is deferred until after the unhandled-error model and embedding
API are stable. Games commonly benefit more from host-level script isolation
and a useful stack trace than from prematurely designed exceptions.

## 11. Default prelude and standard-library baseline

The following basic functions are always available without an import:

- `print(value, ...) -> nil` writes values through the host's normal output
  channel, separated by one space and followed by a newline.
- `len(value) -> Number` returns the size of a String, List, or Map.
- `str(value) -> String` uses the language's canonical value conversion.
- `type(value) -> String` returns the stable language type name.

`assets` and `storage` are also always available as described in section 9.3.
This default prelude is part of the 2.0 language profile; these names are
ordinary runtime bindings, not parser keywords or special bytecode.

Additional standard-library modules are:

- `std.console`: structured logging hooks beyond `print`.
- `std.math`: basic pure math; no implicit time or random state.
- `std.string`: conversion, length, searching, splitting, and immutable
  transformations.
- `std.list` and `std.map`: helpers beyond the native methods.
- `std.random`: explicit seeded random generators.

`print` is an ordinary prelude function, not a parser keyword or special
bytecode instruction. It accepts values directly; formatted output is a
separate future feature and must have its own documented placeholder rules.

All user-visible rendering of values uses one canonical conversion routine.
For example, a list prints recursively and a map prints arbitrary values
safely; no path may assume that a map value is a String.

## 12. Implementation requirements

These requirements exist to keep language semantics separate from VM details:

1. The VM must have explicit stack-capacity checks, operand type checks, and
   index checks before accessing storage.
2. Garbage collection must mark every object reachable from stacks, frames,
   closures, modules, globals, native handles, and compiler roots.
3. A string hash is computed from immutable contents. Interning is an optional
   optimisation and must never make mutation observable.
4. Map hashing and equality must use the same value semantics as `==` for
   allowed key types.
5. VM state is per-instance (`VM*`), not a process-global singleton. Multiple
   VMs may exist sequentially; concurrent use is optional but must be explicit.
6. The public host API includes VM creation, destruction, execution, module
   registration, diagnostics, and an output callback. It must not require a
   CLI `main()` function to be linked into an embedding application.
7. Bytecode is an internal format. It may change between releases and must be
   validated before execution if it can be loaded from disk.

## 13. Progress

- Added `let` alongside `var`, with block scoping and assignment.
- Functions support recursion and lexical closures. Classes support
  inheritance, `this`, `super`, and bound methods.
- List and Map literals support direct and chained indexing and assignment.
- Lists now have the full method set described above, including negative
  indexes and checked runtime errors.
- Maps now enforce safe key types, preserve insertion order, and provide the
  specified methods and `length` property.
- Strings support validated escapes, compare by content, and only concatenate
  with other Strings. Lists and Maps have safe structural equality.
- Added the `len`, `type`, and `str` prelude functions, including cycle-safe
  conversion in `str`.
- Division, modulo, collection operations, and core natives use checked runtime
  errors and stack traces instead of crashing the process.
- `break` cleans up locals and captured variables correctly, including in
  nested loops and functions.
- Recursive containers render safely, and the VM checks stack boundaries.
- Added an organised language test suite covering the core syntax,
  collections, standard functions, errors, and regressions.
- Removed the legacy unaliased GUI import path from the compiler and VM.
- Registered the legacy GUI adapter as a normal namespaced native module.
- Added a per-VM host API with callbacks, native capabilities, and function calls.
- Added aliased native-module imports with cached, read-only namespaces.
- Added registered source modules with isolated globals and `export` for
  existing declaration forms.
- Source modules can import cached dependencies through opaque host-resolved
  identifiers, with source-aware diagnostics and circular-import errors.
- The CLI resolves safe project-local source modules relative to the entry file.
- Module imports derive an alias from the final name component when `as` is omitted.
- The CLI loads the source-defined `std.math` module from its shipped standard library.
- Shortened embedding and build identifiers to the `Pb`/`pb` prefix.

use "std.ui" as ui;

let f = ui.TextField(5);
print(f.text == "" and f.focused == false);
f.insertChar("H");
f.insertChar("i");
f.insertChar("!");
print(f.text);
f.moveCursor(-2);
f.insertChar("x");
print(f.text);
f.eraseOne();
print(f.text);
f.moveCursor(-10);
print(f.cursor);
f.moveCursor(99);
print(f.cursor);
f.insertChar("\n");
print(f.text);
let g = ui.TextField(2);
g.focused = true;
g.update(0.016);
print(g.text);
print(g.submitted);
let h = ui.TextField(0);
h.focused = true;
h.update(0.016);
print(len(h.text));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|Hi!
//|Hxi!
//|Hi!
//|0
//|3
//|Hi!
//|AA
//|false
//|16
// END EXPECTED OUTPUT

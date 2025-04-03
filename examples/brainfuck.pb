// Initialize
var program = strInput();
var length = program.size();

var mem_size = 256;
var memory = [];
for (var i = 0; i < mem_size; i = i + 1) { memory.push(0); }

var pointer = 0;
var output = "";

fun asciiToChar(ascii) {
    if (ascii == 32) { return " "; }
    else if (ascii == 33) { return "!"; }
    else if (ascii == 34) { return "\"; }
    else if (ascii == 35) { return "#"; }
    else if (ascii == 36) { return "$"; }
    else if (ascii == 37) { return "%"; }
    else if (ascii == 38) { return "&"; }
    else if (ascii == 39) { return "'"; }
    else if (ascii == 40) { return "("; }
    else if (ascii == 41) { return ")"; }
    else if (ascii == 42) { return "*"; }
    else if (ascii == 43) { return "+"; }
    else if (ascii == 44) { return ","; }
    else if (ascii == 45) { return "-"; }
    else if (ascii == 46) { return "."; }
    else if (ascii == 47) { return "/"; }
    else if (ascii == 48) { return "0"; }
    else if (ascii == 49) { return "1"; }
    else if (ascii == 50) { return "2"; }
    else if (ascii == 51) { return "3"; }
    else if (ascii == 52) { return "4"; }
    else if (ascii == 53) { return "5"; }
    else if (ascii == 54) { return "6"; }
    else if (ascii == 55) { return "7"; }
    else if (ascii == 56) { return "8"; }
    else if (ascii == 57) { return "9"; }
    else if (ascii == 58) { return ":"; }
    else if (ascii == 59) { return ";"; }
    else if (ascii == 60) { return "<"; }
    else if (ascii == 61) { return "="; }
    else if (ascii == 62) { return ">"; }
    else if (ascii == 63) { return "?"; }
    else if (ascii == 64) { return "@"; }
    else if (ascii == 65) { return "A"; }
    else if (ascii == 66) { return "B"; }
    else if (ascii == 67) { return "C"; }
    else if (ascii == 68) { return "D"; }
    else if (ascii == 69) { return "E"; }
    else if (ascii == 70) { return "F"; }
    else if (ascii == 71) { return "G"; }
    else if (ascii == 72) { return "H"; }
    else if (ascii == 73) { return "I"; }
    else if (ascii == 74) { return "J"; }
    else if (ascii == 75) { return "K"; }
    else if (ascii == 76) { return "L"; }
    else if (ascii == 77) { return "M"; }
    else if (ascii == 78) { return "N"; }
    else if (ascii == 79) { return "O"; }
    else if (ascii == 80) { return "P"; }
    else if (ascii == 81) { return "Q"; }
    else if (ascii == 82) { return "R"; }
    else if (ascii == 83) { return "S"; }
    else if (ascii == 84) { return "T"; }
    else if (ascii == 85) { return "U"; }
    else if (ascii == 86) { return "V"; }
    else if (ascii == 87) { return "W"; }
    else if (ascii == 88) { return "X"; }
    else if (ascii == 89) { return "Y"; }
    else if (ascii == 90) { return "Z"; }
    else if (ascii == 91) { return "["; }
    else if (ascii == 92) { return "\\"; }
    else if (ascii == 93) { return "]"; }
    else if (ascii == 94) { return "^"; }
    else if (ascii == 95) { return "_"; }
    else if (ascii == 96) { return "`"; }
    else if (ascii == 97) { return "a"; }
    else if (ascii == 98) { return "b"; }
    else if (ascii == 99) { return "c"; }
    else if (ascii == 100) { return "d"; }
    else if (ascii == 101) { return "e"; }
    else if (ascii == 102) { return "f"; }
    else if (ascii == 103) { return "g"; }
    else if (ascii == 104) { return "h"; }
    else if (ascii == 105) { return "i"; }
    else if (ascii == 106) { return "j"; }
    else if (ascii == 107) { return "k"; }
    else if (ascii == 108) { return "l"; }
    else if (ascii == 109) { return "m"; }
    else if (ascii == 110) { return "n"; }
    else if (ascii == 111) { return "o"; }
    else if (ascii == 112) { return "p"; }
    else if (ascii == 113) { return "q"; }
    else if (ascii == 114) { return "r"; }
    else if (ascii == 115) { return "s"; }
    else if (ascii == 116) { return "t"; }
    else if (ascii == 117) { return "u"; }
    else if (ascii == 118) { return "v"; }
    else if (ascii == 119) { return "w"; }
    else if (ascii == 120) { return "x"; }
    else if (ascii == 121) { return "y"; }
    else if (ascii == 122) { return "z"; }
    else if (ascii == 123) { return "{"; }
    else if (ascii == 124) { return "|"; }
    else if (ascii == 125) { return "}"; }
    else if (ascii == 126) { return "~"; }
    else { return ""; }
}

fun findMatchingBracket(pc, direction) {
    var loop_level = 1;
    while (loop_level > 0) {
        pc = pc + direction;
        if (program[pc] == "[") {
            if (direction == 1) { loop_level = loop_level + 1; }
            else { loop_level = loop_level - 1; }
        } else if (program[pc] == "]") {
            if (direction == 1) { loop_level = loop_level - 1; }
            else { loop_level = loop_level + 1; }
        }
    }
    return pc;
}

fun executeInstruction(pc) {
    if (program[pc] == "+") { memory[pointer] = memory[pointer] + 1; }
    else if (program[pc] == "-") { memory[pointer] = memory[pointer] - 1; }
    else if (program[pc] == ">") { pointer = pointer + 1; }
    else if (program[pc] == "<") { pointer = pointer - 1; }
    else if (program[pc] == "[") {
        if (memory[pointer] == 0) { pc = findMatchingBracket(pc, 1); }
    }
    else if (program[pc] == "]") {
        if (memory[pointer] != 0) { pc = findMatchingBracket(pc, -1); }
    }
    else if (program[pc] == ".") {
        output = output + asciiToChar(memory[pointer]);
    }
    return pc;
}

for (var pc = 0; pc < length; pc = pc + 1) {
    pc = executeInstruction(pc);
}

print(output);


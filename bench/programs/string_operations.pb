let count = 15000;
let checksum = 0;
let words = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta"];

let tags = [];
for (let i = 0; i < count; i = i + 1) {
  let tag = "record:" + str(i % 100) + ":" + words[i % 8] + "#" + str(i);
  tags.push(tag);
  checksum = checksum + len(tag);
}

let matches = 0;
for (let i = 0; i < count; i = i + 1) {
  let s = tags[i];
  if (s == "record:10:gamma#10" or s == "record:20:epsilon#20" or s == "record:50:alpha#50") {
    matches = matches + 1;
  }
}
checksum = checksum + matches * 1000;

let delimiter_count = 0;
for (let i = 0; i < 3000; i = i + 1) {
  let s = tags[i];
  let slen = len(s);
  for (let j = 0; j < slen; j = j + 1) {
    let ch = s[j];
    if (ch == ":" or ch == "#") {
      delimiter_count = delimiter_count + 1;
    }
  }
}
checksum = checksum + delimiter_count;

let total_block_len = 0;
for (let p = 0; p < 300; p = p + 1) {
  let paragraph = "";
  for (let w = 0; w < 30; w = w + 1) {
    if (w > 0) {
      paragraph = paragraph + " ";
    }
    paragraph = paragraph + words[(p + w) % 8];
  }
  total_block_len = total_block_len + len(paragraph);
}
checksum = checksum + total_block_len;

print(checksum);

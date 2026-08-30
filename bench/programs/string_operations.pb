var count = 15000;
var checksum = 0;
var words = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta"];

var tags = [];
for (var i = 0; i < count; i = i + 1) {
  var tag = "record:" + str(i % 100) + ":" + words[i % 8] + "#" + str(i);
  tags.push(tag);
  checksum = checksum + len(tag);
}

var matches = 0;
for (var i = 0; i < count; i = i + 1) {
  var s = tags[i];
  if (s == "record:10:gamma#10" or s == "record:20:epsilon#20" or s == "record:50:alpha#50") {
    matches = matches + 1;
  }
}
checksum = checksum + matches * 1000;

var delimiter_count = 0;
for (var i = 0; i < 3000; i = i + 1) {
  var s = tags[i];
  var slen = len(s);
  for (var j = 0; j < slen; j = j + 1) {
    var ch = s[j];
    if (ch == ":" or ch == "#") {
      delimiter_count = delimiter_count + 1;
    }
  }
}
checksum = checksum + delimiter_count;

var total_block_len = 0;
for (var p = 0; p < 300; p = p + 1) {
  var paragraph = "";
  for (var w = 0; w < 30; w = w + 1) {
    if (w > 0) {
      paragraph = paragraph + " ";
    }
    paragraph = paragraph + words[(p + w) % 8];
  }
  total_block_len = total_block_len + len(paragraph);
}
checksum = checksum + total_block_len;

print(checksum);

class TreeNode {
  init(item, left, right) {
    this.item = item;
    this.left = left;
    this.right = right;
  }
}

fun bottomUpTree(item, depth) {
  if (depth > 0) {
    return TreeNode(item, bottomUpTree(2 * item - 1, depth - 1), bottomUpTree(2 * item, depth - 1));
  }
  return TreeNode(item, nil, nil);
}

fun itemCheck(node) {
  if (node.left == nil) return node.item;
  return node.item + itemCheck(node.left) - itemCheck(node.right);
}

fun main() {
  let minDepth = 4;
  let maxDepth = 12;
  let stretchDepth = maxDepth + 1;

  let stretchTree = bottomUpTree(0, stretchDepth);
  let stretchCheck = itemCheck(stretchTree);

  let longLivedTree = bottomUpTree(0, maxDepth);

  let totalCheck = stretchCheck;
  for (var depth = minDepth; depth <= maxDepth; depth = depth + 2) {
    var iterations = 1;
    for (var k = 0; k < (maxDepth - depth + minDepth); k = k + 1) {
      iterations = iterations * 2;
    }
    var check = 0;
    for (var i = 1; i <= iterations; i = i + 1) {
      check = check + itemCheck(bottomUpTree(i, depth));
      check = check + itemCheck(bottomUpTree(-i, depth));
    }
    totalCheck = totalCheck + check;
  }

  totalCheck = totalCheck + itemCheck(longLivedTree);
  print(totalCheck);
}

main();


class Node {
  init(value) {
    this.value = value;
    this.left = nil;
    this.right = nil;
  }
  setLeft(node) {
    this.left = node;
  }
  setRight(node) {
    this.right = node;
  }
}
fun inorder(node) {
  if (node == nil) return;
  inorder(node.left);
  print(node.value);
  inorder(node.right);
}
var root = Node(5);
root.setLeft(Node(3));
root.setRight(Node(7));
root.left.setLeft(Node(2));
root.left.setRight(Node(4));
root.right.setLeft(Node(6));
root.right.setRight(Node(8));
inorder(root);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|2
//|3
//|4
//|5
//|6
//|7
//|8
// END EXPECTED OUTPUT

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

class BinaryTree {
    init(root) {
        this.root = root;
    }

    inorder(node) {
        if (node == nil) {
            return;
        }

        // Traverse left subtree
        this.inorder(node.left);

        // Print the current node's value
        print(node.value);

        // Traverse right subtree
        this.inorder(node.right);
    }

    startInorder() {
        this.inorder(this.root);
    }
}

// Create nodes
var root = Node(5);
var node1 = Node(3);
var node2 = Node(7);
var node3 = Node(2);
var node4 = Node(4);
var node5 = Node(6);
var node6 = Node(8);

// Build tree structure
root.setLeft(node1);
root.setRight(node2);
node1.setLeft(node3);
node1.setRight(node4);
node2.setLeft(node5);
node2.setRight(node6);

// Create tree and traverse inorder
var tree = BinaryTree(root);
tree.startInorder();

// Expected Output (Inorder Traversal):
// 2
// 3
// 4
// 5
// 6
// 7
// 8

class Graph {
  init() {
    this.edges = [];
  }

  addEdge(v1, v2) {
    var temp = [v1, v2];
    this.edges.push(temp);
  }

  traverse(start) {
    var visited = {};
    var queue = [];
    queue.push(start);
    visited[start] = true;

    while(queue.size() > 0) {
      var vertex = queue[0];
      queue.remove(0);
      print(vertex);

      for (var i = 0; i < this.edges.size(); i = i + 1) {
        var edge = this.edges[i];
        if (edge[0] == vertex and !visited[edge[1]]) {
          queue.push(edge[1]);
          visited[edge[1]] = true;
        } else if (edge[1] == vertex and !visited[edge[0]]) {
          queue.push(edge[0]);
          visited[edge[0]] = true;
        }
      }
    }
  }
}

var graph = Graph();

graph.addEdge(1, 2);
graph.addEdge(2, 0);
graph.addEdge(1, 0);

graph.traverse(1);
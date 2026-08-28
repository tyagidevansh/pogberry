use "std.math";

fun heuristic(x1, y1, x2, y2) {
  return math.abs(x1 - x2) + math.abs(y1 - y2);
}

fun findPath(gridWidth, gridHeight, startX, startY, goalX, goalY, walls) {
  let openList = [[startX, startY]];
  let gScore = {};
  let fScore = {};
  
  let startKey = str(startX) + "," + str(startY);
  gScore[startKey] = 0;
  fScore[startKey] = heuristic(startX, startY, goalX, goalY);

  let closed = {};

  while (len(openList) > 0) {
    // Find node with lowest fScore
    var lowestIdx = 0;
    var lowestF = 999999;
    for (var i = 0; i < len(openList); i = i + 1) {
      let node = openList[i];
      let k = str(node[0]) + "," + str(node[1]);
      let f = fScore.get(k, 999999);
      if (f < lowestF) {
        lowestF = f;
        lowestIdx = i;
      }
    }

    let current = openList[lowestIdx];
    let cx = current[0];
    let cy = current[1];
    let currentKey = str(cx) + "," + str(cy);

    if (cx == goalX and cy == goalY) {
      return gScore[currentKey];
    }

    openList.removeAt(lowestIdx);
    closed[currentKey] = true;

    // 4 neighbors: Up, Down, Left, Right
    let dxs = [0, 0, -1, 1];
    let dys = [-1, 1, 0, 0];

    for (var d = 0; d < 4; d = d + 1) {
      let nx = cx + dxs[d];
      let ny = cy + dys[d];

      if (nx >= 0 and nx < gridWidth and ny >= 0 and ny < gridHeight) {
        let neighborKey = str(nx) + "," + str(ny);
        if (!walls.has(neighborKey) and !closed.has(neighborKey)) {
          let tentativeG = gScore[currentKey] + 1;
          let existingG = gScore.get(neighborKey, 999999);

          if (tentativeG < existingG) {
            gScore[neighborKey] = tentativeG;
            fScore[neighborKey] = tentativeG + heuristic(nx, ny, goalX, goalY);

            var inOpen = false;
            for (var oi = 0; oi < len(openList); oi = oi + 1) {
              let onode = openList[oi];
              if (onode[0] == nx and onode[1] == ny) {
                inOpen = true;
                break;
              }
            }
            if (!inOpen) {
              openList.push([nx, ny]);
            }
          }
        }
      }
    }
  }

  return -1;
}

fun main() {
  let W = 25;
  let H = 25;
  let walls = {};

  for (var x = 0; x < W; x = x + 1) {
    for (var y = 0; y < H; y = y + 1) {
      if ((x != 0 or y != 0) and (x != W - 1 or y != H - 1)) {
        if ((x * 7 + y * 13) % 5 == 0) {
          walls[str(x) + "," + str(y)] = true;
        }
      }
    }
  }

  var totalLength = 0;
  for (var run = 0; run < 40; run = run + 1) {
    let pathLen = findPath(W, H, 0, 0, W - 1, H - 1, walls);
    totalLength = totalLength + pathLen;
  }

  print(totalLength);
}

main();


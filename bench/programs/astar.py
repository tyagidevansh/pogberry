def heuristic(x1, y1, x2, y2):
    return abs(x1 - x2) + abs(y1 - y2)


def find_path(grid_width, grid_height, start_x, start_y, goal_x, goal_y, walls):
    open_list = [[start_x, start_y]]
    g_score = {}
    f_score = {}

    start_key = f"{start_x},{start_y}"
    g_score[start_key] = 0
    f_score[start_key] = heuristic(start_x, start_y, goal_x, goal_y)

    closed = {}

    while len(open_list) > 0:
        lowest_idx = 0
        lowest_f = 999999
        for i in range(len(open_list)):
            node = open_list[i]
            k = f"{node[0]},{node[1]}"
            f = f_score.get(k, 999999)
            if f < lowest_f:
                lowest_f = f
                lowest_idx = i

        current = open_list[lowest_idx]
        cx = current[0]
        cy = current[1]
        current_key = f"{cx},{cy}"

        if cx == goal_x and cy == goal_y:
            return g_score[current_key]

        open_list.pop(lowest_idx)
        closed[current_key] = True

        dxs = [0, 0, -1, 1]
        dys = [-1, 1, 0, 0]

        for d in range(4):
            nx = cx + dxs[d]
            ny = cy + dys[d]

            if 0 <= nx < grid_width and 0 <= ny < grid_height:
                neighbor_key = f"{nx},{ny}"
                if neighbor_key not in walls and neighbor_key not in closed:
                    tentative_g = g_score[current_key] + 1
                    existing_g = g_score.get(neighbor_key, 999999)

                    if tentative_g < existing_g:
                        g_score[neighbor_key] = tentative_g
                        f_score[neighbor_key] = tentative_g + heuristic(
                            nx, ny, goal_x, goal_y
                        )

                        in_open = any(
                            onode[0] == nx and onode[1] == ny
                            for onode in open_list
                        )
                        if not in_open:
                            open_list.append([nx, ny])

    return -1


def main():
    w = 25
    h = 25
    walls = {}

    for x in range(w):
        for y in range(h):
            if (x != 0 or y != 0) and (x != w - 1 or y != h - 1):
                if (x * 7 + y * 13) % 5 == 0:
                    walls[f"{x},{y}"] = True

    total_length = 0
    for _ in range(40):
        path_len = find_path(w, h, 0, 0, w - 1, h - 1, walls)
        total_length += path_len

    print(f"{float(total_length):g}")


if __name__ == "__main__":
    main()


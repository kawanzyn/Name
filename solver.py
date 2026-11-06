"""IDA* solver for the 4x4 Sea Beast sliding puzzle.

Input board: 16 integers, row-major; 0 is the empty square.
Output moves: 1-based positions of tiles to click, in order.
"""
from __future__ import annotations

import time
from collections import deque

GOAL = tuple(range(1, 16)) + (0,)
GOAL_POS = {tile: i for i, tile in enumerate(GOAL) if tile}
NEIGHBORS = []
for pos in range(16):
    r, c = divmod(pos, 4)
    ns = []
    if r: ns.append(pos - 4)
    if r < 3: ns.append(pos + 4)
    if c: ns.append(pos - 1)
    if c < 3: ns.append(pos + 1)
    NEIGHBORS.append(tuple(ns))

_WD_ROW = None
_WD_COL = None


class SearchLimit(Exception):
    def __init__(self, nodes, bound, elapsed):
        super().__init__("search limit")
        self.nodes = nodes
        self.bound = bound
        self.elapsed = elapsed


def validate(board):
    if not isinstance(board, (list, tuple)) or len(board) != 16:
        raise ValueError("board precisa conter exatamente 16 numeros")
    if any(type(x) is not int for x in board):
        raise ValueError("todas as casas precisam ser inteiros")
    if set(board) != set(range(16)):
        raise ValueError("board precisa conter 0 a 15, sem repeticoes")
    return tuple(board)


def solvable(board):
    vals = [x for x in board if x]
    inversions = sum(vals[i] > vals[j] for i in range(15) for j in range(i + 1, 15))
    blank = board.index(0)
    row_from_bottom = 4 - (blank // 4)
    return (inversions + row_from_bottom) % 2 == 1


def _build_walking_distance():
    """Build the complete 4x4 Walking Distance abstraction table."""
    counts = [0] * 16
    for line in range(4):
        counts[line * 4 + line] = 4 - (line == 3)
    start = (3, tuple(counts))
    distances = {start: 0}
    queue = deque([start])

    while queue:
        blank_line, state_counts = queue.popleft()
        distance = distances[(blank_line, state_counts)]
        for adjacent in (blank_line - 1, blank_line + 1):
            if not 0 <= adjacent < 4:
                continue
            for goal_line in range(4):
                source = adjacent * 4 + goal_line
                if state_counts[source] == 0:
                    continue
                changed = list(state_counts)
                changed[source] -= 1
                changed[blank_line * 4 + goal_line] += 1
                next_state = (adjacent, tuple(changed))
                if next_state not in distances:
                    distances[next_state] = distance + 1
                    queue.append(next_state)
    return distances


def _walking_distance(board, table, axis):
    blank = board.index(0)
    br, bc = divmod(blank, 4)
    blank_line = br if axis == 0 else bc
    counts = [0] * 16
    for pos, tile in enumerate(board):
        if not tile:
            continue
        r, c = divmod(pos, 4)
        goal = GOAL_POS[tile]
        gr, gc = divmod(goal, 4)
        line = r if axis == 0 else c
        goal_line = gr if axis == 0 else gc
        counts[line * 4 + goal_line] += 1
    return table[(blank_line, tuple(counts))]


def _manhattan_linear_conflict(board):
    total = 0
    for i, tile in enumerate(board):
        if tile:
            goal = GOAL_POS[tile]
            r, c = divmod(i, 4)
            gr, gc = divmod(goal, 4)
            total += abs(r - gr) + abs(c - gc)

    conflicts = 0
    used_tiles = set()
    for r in range(4):
        candidates = []
        for c1 in range(4):
            t1 = board[r * 4 + c1]
            if not t1 or GOAL_POS[t1] // 4 != r:
                continue
            for c2 in range(c1 + 1, 4):
                t2 = board[r * 4 + c2]
                if t2 and GOAL_POS[t2] // 4 == r:
                    if GOAL_POS[t1] % 4 > GOAL_POS[t2] % 4:
                        candidates.append((c1, c2))
        for a, b in candidates:
            ia, ib = r * 4 + a, r * 4 + b
            if ia not in used_tiles and ib not in used_tiles:
                used_tiles.add(ia)
                used_tiles.add(ib)
                conflicts += 1

    for c in range(4):
        candidates = []
        for r1 in range(4):
            t1 = board[r1 * 4 + c]
            if not t1 or GOAL_POS[t1] % 4 != c:
                continue
            for r2 in range(r1 + 1, 4):
                t2 = board[r2 * 4 + c]
                if t2 and GOAL_POS[t2] % 4 == c:
                    if GOAL_POS[t1] // 4 > GOAL_POS[t2] // 4:
                        candidates.append((r1, r2))
        for a, b in candidates:
            ia, ib = a * 4 + c, b * 4 + c
            if ia not in used_tiles and ib not in used_tiles:
                used_tiles.add(ia)
                used_tiles.add(ib)
                conflicts += 1
    return total + 2 * conflicts


def heuristic(board):
    global _WD_ROW, _WD_COL
    if _WD_ROW is None:
        _WD_ROW = _build_walking_distance()
        _WD_COL = _WD_ROW
    walking = (
        _walking_distance(board, _WD_ROW, 0)
        + _walking_distance(board, _WD_COL, 1)
    )
    return max(walking, _manhattan_linear_conflict(board))


def solve(board, time_limit=20.0, node_limit=20_000_000):
    started = time.perf_counter()
    start_board = validate(board)
    if not solvable(start_board):
        raise ValueError("tabuleiro impossivel de resolver (paridade)")
    if start_board == GOAL:
        return [], 0, 0.0

    initial_h = heuristic(start_board)
    work = list(start_board)
    blank = work.index(0)
    path = []
    nodes = 0
    deadline = time.perf_counter() + max(0.05, min(float(time_limit), 20.0))
    found = object()
    bound = initial_h

    def dfs(g, current_bound, hole, previous_hole, h, seen):
        nonlocal nodes
        nodes += 1
        if nodes > node_limit or time.perf_counter() > deadline:
            raise SearchLimit(nodes, current_bound, time.perf_counter() - started)
        f = g + h
        if f > current_bound:
            return f
        if h == 0:
            return found

        minimum = float("inf")
        choices = []
        for nxt in NEIGHBORS[hole]:
            if nxt == previous_hole:
                continue
            tile = work[nxt]
            work[hole], work[nxt] = tile, 0
            next_h = heuristic(work)
            work[nxt], work[hole] = tile, 0
            choices.append((next_h, nxt, tile))
        choices.sort(key=lambda item: item[0])

        for next_h, nxt, tile in choices:
            work[hole], work[nxt] = tile, 0
            state = tuple(work)
            next_g = g + 1
            old_g = seen.get(state)
            if old_g is not None and old_g <= next_g:
                work[nxt], work[hole] = tile, 0
                continue
            seen[state] = next_g
            path.append(nxt + 1)
            result = dfs(next_g, current_bound, nxt, hole, next_h, seen)
            if result is found:
                return found
            path.pop()
            work[nxt], work[hole] = tile, 0
            if result < minimum:
                minimum = result
        return minimum

    while True:
        seen = {tuple(work): 0}
        result = dfs(0, bound, blank, -1, initial_h, seen)
        if result is found:
            return list(path), nodes, time.perf_counter() - started
        if result == float("inf"):
            raise ValueError("nenhuma solucao encontrada")
        bound = result


def solve_safe(board, time_limit=20.0, node_limit=20_000_000):
    started = time.perf_counter()
    try:
        path, nodes, _ = solve(board, time_limit, node_limit)
        return {
            "ok": True,
            "moves": path,
            "move_count": len(path),
            "nodes": nodes,
            "elapsed_ms": round((time.perf_counter() - started) * 1000, 2),
        }
    except SearchLimit as exc:
        return {
            "ok": False,
            "error": "limite de tempo ou de nos atingido",
            "nodes": exc.nodes,
            "bound": exc.bound,
            "elapsed_ms": round((time.perf_counter() - started) * 1000, 2),
        }
    except ValueError as exc:
        return {
            "ok": False,
            "error": str(exc),
            "elapsed_ms": round((time.perf_counter() - started) * 1000, 2),
        }

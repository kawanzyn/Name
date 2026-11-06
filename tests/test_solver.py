import unittest

from solver import GOAL, solve, solvable


def apply_moves(board, moves):
    board = list(board)
    for target in moves:
        hole = board.index(0)
        tile_pos = target - 1
        if tile_pos not in __import__("solver").NEIGHBORS[hole]:
            raise AssertionError(f"move {target} is not adjacent to blank {hole + 1}")
        board[hole], board[tile_pos] = board[tile_pos], board[hole]
    return tuple(board)


class SolverTests(unittest.TestCase):
    def test_already_solved(self):
        moves, _, _ = solve(GOAL)
        self.assertEqual(moves, [])

    def test_one_move(self):
        board = tuple(range(1, 15)) + (0, 15)
        moves, _, _ = solve(board)
        self.assertEqual(apply_moves(board, moves), GOAL)

    def test_two_moves(self):
        # Scramble the goal by moving the blank up, then left.
        board = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0, 11, 13, 14, 15, 12)
        moves, _, _ = solve(board)
        self.assertEqual(apply_moves(board, moves), GOAL)

    def test_unsolvable_parity(self):
        board = (2, 1) + tuple(range(3, 16)) + (0,)
        self.assertFalse(solvable(board))
        with self.assertRaises(ValueError):
            solve(board)


if __name__ == "__main__":
    unittest.main()

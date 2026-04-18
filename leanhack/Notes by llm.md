What a llm told me (can be wrong)

---
# Code Understanding Notes

## Overview
This is a **Z3-based SAT/SMT solver** for a logic puzzle where people arranged in a grid are classified as either **Innocent (0)** or **Criminal (1)**. Clues are added incrementally, and the solver deduces roles through contradiction.

---

## Constants & Helpers

- **`INNOCENT = 0` / `CRIMINAL = 1`**: Integer encoding of roles (not enum — enables arithmetic like `sum()` to count criminals).
- **`role_to_str(role)`**: Pretty-prints `0 → "Innocent"`, `1 → "Criminal"`.
- **`Even(x)` / `Odd(x)`**: Z3 predicates — `Even` asserts ∃q. x = 2q; `Odd` is its negation. Useful for parity-based clues.

---

## `IntersectionList`

A `list` subclass that overrides `&` (bitwise AND) to perform **set-like intersection** while preserving list ordering. Used when combining spatial filters (e.g., `neighbors(A) & edges`).

---

## `ClueSolver` — Core Solver Class

### State
| Attribute | Purpose |
|-----------|---------|
| `self.known` | Set of Z3 variables whose values have been proven |
| `self.s` | Z3 `Solver` instance holding all constraints |
| `self.grid` | 2D list of person-name strings (the puzzle layout) |
| `self.people` | Dict mapping person name → Z3 `Int` variable |

> **Human notes**
> Z3 variables are just integer values tied to person's name

### `__init__(grid)`
- Creates one Z3 `Int` variable per person in the grid.
- Adds domain constraint: each variable ∈ {0, 1} (via `Or(p == 0, p == 1)`).

### `find_new_info()`
- **Contradiction-based deduction**: For each unknown person, tries both `p ≠ 0` and `p ≠ 1`.
  - If `p ≠ 0` is unsatisfiable → `p` must be Innocent.
  - If `p ≠ 1` is unsatisfiable → `p` must be Criminal.
- Uses `push()`/`pop()` to test assumptions without permanently modifying the solver.
- Prints results; reports if nothing new was deduced.

### `add(clue)`
- Adds a Z3 constraint (boolean expression) to the solver.
- Checks for inconsistency (`unsat` after adding).
- Calls `find_new_info()` to propagate deductions.
- Checks if puzzle is fully solved.

### `find_person(person)`
- Scans `self.grid` to find the `(row, col)` coordinates of a person by name.

---

## Spatial Query Methods (Decorated with `@to_persons`)

### `@to_persons` decorator
- Wraps a generator that yields **person name strings**.
- Converts the output into an `IntersectionList` of **Z3 Int variables** (from `self.people`).
- This enables:
  - Set intersection via `&` between spatial queries.
  - Direct use in Z3 expressions (since elements are Z3 variables).

### Methods

| Method | Returns Z3 vars for people... |
|--------|-------------------------------|
| `neighbors(person)` | In the 8 surrounding cells (king's move) |
| `above(person)` | Same column, rows above |
| `below(person)` | Same column, rows below |
| `left_of(person)` | Same row, columns to the left |
| `right_of(person)` | Same row, columns to the right |
| `corners()` | The 4 corner cells of the grid |
| `edges()` | All cells on the perimeter (deduplicated, sorted) |
| `row(i)` | People in 1-indexed row `i` |
| `column(a)` | People in column labeled by letter `a` (A=0, B=1, ...) |

> **`get_from_grid(*coords)`**: Helper that safely yields grid names for valid `(row, col)` pairs (silently skips out-of-bounds).

---

## Counting & Connectivity

### `num_innocents(people)` / `num_criminals(people)`
- Since Criminal = 1 and Innocent = 0:
  - `num_criminals = sum(people)` — Z3 arithmetic sums the 0/1 variables.
  - `num_innocents = len(people) - sum(people)` — total minus criminals.

### `connected(role, people)`
- Encodes that all people of a given `role` in the list form a **contiguous block** (no "gaps" of the opposite role splitting them).
- For each person `p`, it forbids the pattern: `p` is opposite-role AND there exists at least one `role` person **before** `p` AND at least one `role` person **after** `p`.
- This means no opposite-role person can sit between two role people — i.e., the role-people are connected/contiguous in the sequence.

> ⚠️ **Caveat**: Uses `list.index(p)` which finds the **first** occurrence. If the same Z3 variable appeared twice in a list, this could be incorrect. In practice, each person appears once in these lists.

---

## Typical Usage Pattern

```python
grid = [["Alice", "Bob", "Carol"],
        ["Dave", "Eve",  "Frank"]]
s = ClueSolver(grid)

# "Exactly 3 criminals"
s.add(s.num_criminals(list(s.people.values())) == 3)

# "Alice's neighbors are all criminals"
s.add(s.num_innocents(s.neighbors("Alice")) == 0)

# "The criminals in row 1 are connected"
s.add(s.connected(CRIMINAL, s.row(1)))
```

---

import Lean
import Std
open Lean Std

def hello := "world"

-- c₁ ∧ c₂ ... ∧ cₙ => 0 or 1

-- grid = (
--     ("Alice", "Bob", "Carol"),
--     ("Dave", "Eve", "Frank"),
--     ("Grace", "Heidi", "Ivan"),
-- )


-- from cluesbysam_solver import ClueSolver

-- cs = ClueSolver(grid)
-- TODO : make a cluesolver grid

-- from cluesbysam_solver import INNOCENT, CRIMINAL
inductive Role
| Innocent : Role
| Criminal : Role
deriving Repr, BEq, Hashable

structure Person where
    label: Option Role
    name: String
    constraintString: String
deriving Repr, BEq, Hashable

def Person.updateLabel (p : Person) (x : Role) :=
    {
        p with label := some x
    }

abbrev Map α β [BEq α] [Hashable α] := Std.HashMap α β
-- p = cs.people
-- TODO: create a cs, which is a ClueSolver instance

-- a way to reference the complete grid but in structure of people
abbrev People := Map String Person
abbrev Set := Std.HashSet Person

def Person.hasLabel (p : Person) : Bool :=
    match p.label with
    | .none => false
    | .some _ => true

def Set.contains (current : Set) (p : Person) := Std.HashSet.contains (α := Person) current p

structure ClueSolver where
    known: Set
    solver: Type
    grid: Grid
    people: People

-- def ClueSolver.findNewInfo (solver: ClueSolver) :=
--     let newInfo := false
--     let people := solver.people.values
--     let ¬Known := Bool.not · solver.known.contains
--     let ¬Assignable := ·.hasLabel |> Bool.not
--     let ¬Known∧¬Assignable := ¬Assignable · ¬Known
--     people.filter ¬Known∧¬Assignable
--     |>

-- cs.add(p["Frank"] == INNOCENT)
-- make a fn called add which adds constraints to a list/set
-- add : People -> (name: String) (label: Label) -> People
-- def People.add
--     (prev: People)
--     (name: String)
--     (label : Label)
--     : People :=
--     match prev.get? name with
--     | .some person =>
--         match person.label with
--         | .some _ => prev
--         | .none =>
--             let updatedPerson := person.updateLabel label
--             prev.insert name updatedPerson
--     | .none => prev

-- # <Frank> Carol is one of my 3 criminal neighbors
-- cs.add(p["Carol"] == CRIMINAL)
-- cs.add(cs.num_criminals(cs.neighbors("Frank")) == 3)

-- # <Carol> Alice only shares innocent neighbors with Grace
-- shared_neighbors = cs.neighbors("Alice") & cs.neighbors("Grace")
-- cs.add(cs.num_innocents(shared_neighbors) == len(shared_neighbors))

-- # <Dave> The criminals in row 1 are connected
-- cs.add(cs.connected(CRIMINAL, cs.row(1)))

-- # <Eve> There are exactly 2 innocents in column C
-- cs.add(cs.num_innocents(cs.column("C")) == 2)

-- # <Heidi> Only one row has exactly 2 innocents
-- from cluesbysam_solver import AtMost, AtLeast

-- cs.add(AtMost(*(cs.num_innocents(cs.row(i)) == 2 for i in range(1, 4)), 1))
-- cs.add(AtLeast(*(cs.num_innocents(cs.row(i)) == 2 for i in range(1, 4)), 1))

-- # <Ivan> The number of criminals in the corners is even
-- from cluesbysam_solver import Even

-- cs.add(Even(cs.num_criminals(cs.corners())))

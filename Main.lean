import Leanhack
import Smt
import Lean
import Std
import Std.Time
open Lean Std

abbrev Date := Time.PlainDate
def Date.parse := Time.PlainDate.parse

inductive Status where
| Criminal
| Innocent
deriving Repr

-- set_option trace.Meta.synthInstance true

-- /**
--  * @typedef {Object} ClueMetadata
-- structure ClueMetadata where

-- --  * @property {number} [row] - The grid row mentioned (1-5).
--   row: Nat
-- --  * @property {string} [column] - The grid column mentioned (A-D).
--   col: String
-- --  * @property {number} [count] - The number of entities mentioned (e.g., "2 criminals").
--   count: Nat
-- --  * @property {'criminal' | 'innocent'} [target] - The status of the subjects mentioned.
--   target: Status
-- --  * @property {string[]} [subjects] - Names of characters from the grid mentioned in the clue.
--   subjects: Array String
-- --  * @property {string[]} [professions] - Professions mentioned in the clue.
--   professions: Array String
--  */
-- deriving Repr

inductive ClueType where
| Clue : ClueType
| Rule : ClueType
deriving Repr, Inhabited

def List.ofListOption
  {α : Type u}
  (xs : List (Option α)) : Option (List α) :=
  xs.foldr
    (init := some [])
    (f := fun x acc =>
      match x with
      | .none => acc
      | .some x => acc.map (·.cons x))

def Array.ofArrayOption
  {α : Type u}
  (xs : Array (Option α)) : Option (Array α) :=
  xs.foldr (init := [])
  (f := fun x acc =>
    match x with
    | .none => acc
    | .some x => x :: acc)
  |> fun
  | [] => .none
  | ys => .some <| ys.toArray

def Option.flatten
  {α : Type u}
  (x : Option <| Option α)
  : Option α := match x with
    | .some <| .some x => .some x
    | .some <| .none | .none => .none

-- (* Types *)
-- Inductive Row : Type := R1 | R2 | R3 | R4 | R5.
inductive Row where
| R1 : Row
| R2 : Row
| R3 : Row
| R4 : Row
| R5 : Row
deriving Repr
-- Inductive Col : Type := A | B | C | D.
inductive Col where
| A : Col
| B : Col
| C : Col
| D : Col
deriving Repr

structure Grid where
  coord: String
  name: String
  profession: String
  face: String
  initialClue: Option String
deriving Repr

structure ClueMetadata where
  count: Nat
  target: Option Status
  subjects: Array String
deriving Repr

structure ClueProperty where
  text: String
  type_: ClueType
  metadata: Option ClueMetadata
deriving Repr

structure Response where
  date: Option Date
  url: String
  clues: Array ClueProperty
  grid: Array Grid
deriving Repr

instance : ToString Response where
  toString r :=
    instReprResponse.reprPrec r 1000
    |> Format.pretty

-- def Response.ToString (resp : Response) : String :=
--   let date := resp.date
--   let url := resp.url
--   let clues := resp.clues
--   let grid := resp.grid
--   s!"[{date}, {url}, {clues}, {grid}]"

def getFile (path : String) : IO String := do
  let file ← IO.FS.readFile (System.FilePath.mk path)
  return file

def Lean.Json.toClueProperty (json : Json) : ClueProperty :=
  let text := json.getObjValD "text"
    |>.getStr?
    |>.toOption
    |> fun
    | .some x => x
    | .none => ""
  let type_ := json.getObjValD "type"
    |>.getStr?
    |>.toOption
    |>.bind (fun
              | "rule" => .some ClueType.Rule
              | "clue" => .some ClueType.Clue
              | _ => .none)
    |>.get!
  let metadata :=
    let metadata := json.getObjValD "metadata"
    let count :=
      metadata.getObjValD "count"
      |>.getNat?
      |>.toOption
      |> fun
      | .some x => x
      | .none => Nat.zero
    let target :=
      metadata.getObjValD "target"
      |>.getStr?
      |>.toOption
      |>.bind (fun
        | "criminal" => .some Status.Criminal
        | "innocent" => .some Status.Criminal
        | _ => .none)
    let subjects :=
      metadata.getObjValD "subjects"
      |>.getArr?
      |>.map (fun arr => arr.map (fun x => x.getStr?))
      |>.toOption
      |>.map (fun arr => arr.map (·.toOption) |>.ofArrayOption)
      |>.flatten
      |> fun
      | .some x => x
      | .none => #[]
    ClueMetadata.mk count target subjects

  ClueProperty.mk text type_ metadata

def Lean.Json.toGrid (json : Json) : Grid :=
  let coord := json.getObjValD "coord"
    |>.getStr?
    |>.toOption
    |> fun
    | .some x => x
    | .none => ""
  let name := json.getObjValD "name"
    |>.getStr?
    |>.toOption
    |> fun
    | .some x => x
    | .none => ""
  let profession := json.getObjValD "profession"
    |>.getStr?
    |>.toOption
    |> fun
    | .some x => x
    | .none => ""
  let face := json.getObjValD "face"
    |>.getStr?
    |>.toOption
    |> fun
    | .some x => x
    | .none => ""
  let initialClue := json.getObjValD "initialClue"
    |>.getStr?
    |>.toOption

  Grid.mk coord name profession face initialClue

def String.toJson (s: String) : Except String Response := do
  if let .ok jsonString := Json.parse s then
    let date :=
      jsonString.getObjValD "date"
      |>.getStr?
      |>.bind Date.parse
      |>.toOption
    let url :=
      jsonString.getObjValD "url"
      |>.getStr?
      |>.toOption
      |> fun
      | .some x => x
      | .none => ""
    let clues :=
      jsonString.getObjValD "clues"
      |>.getArr?
      |>.toOption
      |>.map (f := fun arr => arr.map (·.toClueProperty))
      |> fun
      | .some x => x
      | .none => #[]
    let grid :=
      jsonString.getObjValD "grid"
      |>.getArr?
      |>.toOption
      |>.map (f := fun arr => arr.map (·.toGrid))
      |> fun
      | .some x => x
      | .none => #[]

    Response.mk date url clues grid
    |> .ok
  else
    .error s!"Failed to parse {s}"


def main : IO Unit := do
  let scrapedJson ← IO.Process.output { cmd := "./scraper-exe", args := #[] }
  let json ← scrapedJson.stdout.toJson |> IO.ofExcept
  IO.println s!"{json}"
-- Inductive Profession : Type := Cop | Accountant | Cook | Coder (* ... other professions *).

-- (* Person is a finite type with 20 inhabitants *)
-- Parameter Person : Type.
-- Parameter persons : list Person. (* exactly 20 distinct elements *)
-- Axiom person_finite : forall p : Person, In p persons.
-- Axiom persons_distinct : NoDup persons.
-- Axiom persons_count : length persons = 20.

-- (* Base functions *)
-- Parameter row : Person -> Row.
-- Parameter col : Person -> Col.
-- Parameter profession : Person -> Profession.
-- Parameter criminal : Person -> Prop.
-- Definition innocent (p : Person) : Prop := ~ criminal p.
-- Axiom criminal_or_innocent : forall p, criminal p \/ innocent p.
-- Axiom not_both : forall p, ~ (criminal p /\ innocent p).

-- (* Column index helper *)
-- Definition colIdx (c : Col) : nat :=
--   match c with
--   | A => 1 | B => 2 | C => 3 | D => 4
--   end.

-- Definition rowNum (r : Row) : nat :=
--   match r with
--   | R1 => 1 | R2 => 2 | R3 => 3 | R4 => 4 | R5 => 5
--   end.

-- (* Orderings *)
-- Definition row_lt (r1 r2 : Row) : Prop := rowNum r1 < rowNum r2.
-- Definition col_lt (c1 c2 : Col) : Prop := colIdx c1 < colIdx c2.

-- (* Neighbourhood *)
-- Definition neighbor (p1 p2 : Person) : Prop :=
--   p1 <> p2 /\
--   abs (rowNum (row p1) - rowNum (row p2)) <= 1 /\
--   abs (colIdx (col p1) - colIdx (col p2)) <= 1.

-- Definition directly_left (p1 p2 : Person) : Prop :=
--   row p1 = row p2 /\ colIdx (col p2) = colIdx (col p1) - 1.

-- Definition directly_right (p1 p2 : Person) : Prop :=
--   row p1 = row p2 /\ colIdx (col p2) = colIdx (col p1) + 1.

-- Definition directly_above (p1 p2 : Person) : Prop :=
--   col p1 = col p2 /\ rowNum (row p2) = rowNum (row p1) + 1.

-- Definition directly_below (p1 p2 : Person) : Prop :=
--   col p1 = col p2 /\ rowNum (row p2) = rowNum (row p1) - 1.

-- Definition left_of (p1 p2 : Person) : Prop :=
--   row p1 = row p2 /\ col_lt (col p1) (col p2).

-- Definition right_of (p1 p2 : Person) : Prop :=
--   row p1 = row p2 /\ col_lt (col p2) (col p1).

-- Definition above (p1 p2 : Person) : Prop :=
--   col p1 = col p2 /\ row_lt (row p1) (row p2).

-- Definition below (p1 p2 : Person) : Prop :=
--   col p1 = col p2 /\ row_lt (row p2) (row p1).

-- (* Between (straight line, same row or same column) *)
-- Definition between (p1 p2 p3 : Person) : Prop :=
--   (row p1 = row p2 /\ row p2 = row p3 /\
--     ((col_lt (col p1) (col p2) /\ col_lt (col p2) (col p3)) \/
--      (col_lt (col p3) (col p2) /\ col_lt (col p2) (col p1))))
--   \/
--   (col p1 = col p2 /\ col p2 = col p3 /\
--     ((row_lt (row p1) (row p2) /\ row_lt (row p2) (row p3)) \/
--      (row_lt (row p3) (row p2) /\ row_lt (row p2) (row p1)))).

-- (* Orthogonal adjacency *)
-- Definition orth_adj (p1 p2 : Person) : Prop :=
--   directly_left p1 p2 \/ directly_right p1 p2 \/
--   directly_above p1 p2 \/ directly_below p1 p2.

-- (* Connectedness (inductive definition) *)
-- Inductive connected : list Person -> Prop :=
-- | connected_singleton : forall p, connected [p]
-- | connected_step : forall (s : list Person) (p q : Person),
--     connected s ->
--     In p s ->
--     ~ In q s ->
--     orth_adj p q ->
--     connected (q :: s).

-- (* Common neighbours *)
-- Definition common_neighbor (p1 p2 p3 : Person) : Prop :=
--   neighbor p1 p3 /\ neighbor p2 p3.

-- (* Counting helpers (using `count` from a finite set library) *)
-- Parameter count : (Person -> Prop) -> nat.
-- Axiom count_empty : count (fun _ => False) = 0.
-- Axiom count_incl : forall (P Q : Person -> Prop),
--   (forall p, P p <-> Q p) -> count P = count Q.
-- (* ... other count axioms for disjoint union, etc. *)

-- Definition shared_innocent_neighbors (p1 p2 : Person) : Person -> Prop :=
--   fun p3 => common_neighbor p1 p2 p3 /\ innocent p3.

-- Definition odd_shared_innocent_neighbors (p1 p2 : Person) : Prop :=
--   count (shared_innocent_neighbors p1 p2) mod 2 = 1.

-- Definition criminal_neighbors (p : Person) : Person -> Prop :=
--   fun n => neighbor p n /\ criminal n.

-- Definition criminal_neighbor_count (p : Person) : nat :=
--   count (criminal_neighbors p).

-- (* "The most" uniquely *)
-- Definition uniquely_most_criminal_neighbors (p : Person) : Prop :=
--   forall q, q <> p -> criminal_neighbor_count p > criminal_neighbor_count q.

-- (* Corner and edge *)
-- Definition corner (p : Person) : Prop :=
--   (row p = R1 \/ row p = R5) /\ (col p = A \/ col p = D).

-- Definition edge (p : Person) : Prop :=
--   row p = R1 \/ row p = R5 \/ col p = A \/ col p = D.

-- (* Interpretations of clue phrases *)
-- (* "All criminals in row r are connected" *)
-- Definition criminals_in_row (r : Row) : Person -> Prop :=
--   fun p => row p = r /\ criminal p.

-- Definition all_criminals_in_row_connected (r : Row) : Prop :=
--   (* at least one criminal, and they form a connected set *)
--   exists p, criminals_in_row r p /\
--   connected (filter (criminals_in_row r) persons).

-- (* "Both means exactly 2" – used in specific clues, not a general definition,
--    but we can note: a phrase "both P" means count(P) = 2. *)

-- (* "More innocent in row r1 than r2" *)
-- Definition more_innocents_in_row (r1 r2 : Row) : Prop :=
--   count (fun p => row p = r1 /\ innocent p) >
--   count (fun p => row p = r2 /\ innocent p).

-- (* Exact numerical clues: "exactly 2 criminal coders" *)
-- Definition exactly_n (n : nat) (P : Person -> Prop) : Prop :=
--   count P = n.

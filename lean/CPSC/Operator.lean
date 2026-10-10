/-
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-/

import CPSC.Certificate

/-!
Operator model on `(R²)^⊗N`.

This file discharges the operator obligation without axioms. A state of `N`
qubits is a function from computational basis strings `Fin N → Bool` to a
commutative ring `R`, so for `R = ℂ` this is exactly `(ℂ²)^⊗N` in the
computational basis. An operator is a map on such states, and operator
product is composition.

Pauli operators act on basis strings in the usual way:

* `Z q` multiplies the amplitude of `b` by `(-1)^(b q)`;
* `X q` flips bit `q`;
* `PiX = ∏ X` flips every bit;
* `Mag = ∑ Z` multiplies by `∑_k (-1)^(b k)`.

Each gate is the rotation `c·I + ι·s·P` for its Pauli generator `P`. With
`ι = i`, `c = cos θ`, and `s = ± sin θ`, and since `P² = I`, this equals
`exp(± i θ P)`. These are the factors `cpsc.channel` applies: `RZZ` is
`c + ι s Z_a Z_b` and `RX` is `c - ι s X_q`. The commutation theorems hold for
every ring, every `ι`, and every pair `(c, s)`. In particular they hold for
every Trotter step size, every `J`, and every `λ`.

Gate indices in `GateKind` are natural numbers. They are read modulo the
lattice size, which matches the periodic ring used by `bondOrbit`. Lattice
sizes are written `n + 1`, so there is always at least one site.
-/

namespace CPSC.Operator

open Lean.Grind

set_option linter.unusedSectionVars false

variable {R : Type} [CommRing R] {n : Nat}

/-- Computational basis strings on `n + 1` sites. -/
abbrev Basis (n : Nat) := Fin (n + 1) → Bool

/-- State vectors: amplitudes on basis strings. -/
abbrev Vec (R : Type) (n : Nat) := Basis n → R

/-- Operators: maps on state vectors. Product is composition. -/
abbrev Op (R : Type) (n : Nat) := Vec R n → Vec R n

/-- `A` and `B` commute as operators. -/
def Commutes (A B : Op R n) : Prop := ∀ v, A (B v) = B (A v)

/-! ## Signs and bit flips -/

/-- `(-1)^x`: the `Z` eigenvalue of a bit. -/
def sgn (x : Bool) : R := if x then -1 else 1

theorem sgn_not (x : Bool) : sgn (R := R) (!x) = - sgn x := by
  cases x <;> simp [sgn] <;> grind

theorem sgn_sq (x : Bool) : sgn (R := R) x * sgn x = 1 := by
  cases x <;> simp [sgn] <;> grind

/-- Flip one bit. -/
def flipAt (q : Fin (n + 1)) (b : Basis n) : Basis n :=
  fun k => if k = q then !b k else b k

/-- Flip every bit. -/
def flipAll (b : Basis n) : Basis n := fun k => !b k

theorem flipAt_flipAll (q : Fin (n + 1)) (b : Basis n) :
    flipAt q (flipAll b) = flipAll (flipAt q b) := by
  funext k
  simp only [flipAt, flipAll]
  split <;> rfl

theorem flipAt_flipAt (q : Fin (n + 1)) (b : Basis n) :
    flipAt q (flipAt q b) = b := by
  funext k
  simp only [flipAt]
  split <;> simp

theorem flipAt_comm (p q : Fin (n + 1)) (b : Basis n) :
    flipAt p (flipAt q b) = flipAt q (flipAt p b) := by
  funext k
  simp only [flipAt]
  split <;> split <;> rfl

/-! ## Pauli operators and the two conserved quantities -/

def Z (q : Fin (n + 1)) : Op R n := fun v b => sgn (b q) * v b

def X (q : Fin (n + 1)) : Op R n := fun v b => v (flipAt q b)

/-- The global spin flip `∏_i X_i`, the `λ ≠ 0` symmetry. -/
def PiX : Op R n := fun v b => v (flipAll b)

/-- Partial magnetization `∑_{k < m} (-1)^(b k)`. -/
def magUpTo (b : Basis n) : Nat → R
  | 0 => 0
  | m + 1 => magUpTo b m + (if h : m < n + 1 then sgn (b ⟨m, h⟩) else 0)

/-- Magnetization eigenvalue `∑_k (-1)^(b k)` of a basis string. -/
def magVal (b : Basis n) : R := magUpTo b (n + 1)

/-- Total magnetization `∑_i Z_i`, the `λ = 0` symmetry. -/
def Mag : Op R n := fun v b => magVal b * v b

theorem Z_sq (q : Fin (n + 1)) (v : Vec R n) : Z q (Z q v) = v := by
  funext b
  simp only [Z]
  have h := sgn_sq (R := R) (b q)
  grind

theorem X_sq (q : Fin (n + 1)) (v : Vec R n) : X q (X q v) = v := by
  funext b
  simp only [X, flipAt_flipAt]

/-! ## Gates: `c·I + ι·s·P` -/

/-- `exp(i θ Z_p Z_q)` with `c = cos θ`, `s = sin θ`, `ι = i`. -/
def rzz (ι c s : R) (p q : Fin (n + 1)) : Op R n :=
  fun v b => (c + ι * s * (sgn (b p) * sgn (b q))) * v b

/-- `exp(-i θ X_q)` with `c = cos θ`, `s = sin θ`, `ι = i`. -/
def rx (ι c s : R) (q : Fin (n + 1)) : Op R n :=
  fun v b => c * v b - ι * s * v (flipAt q b)

/-- `exp(i θ Z_q)` with `c = cos θ`, `s = sin θ`, `ι = i`. -/
def rz (ι c s : R) (q : Fin (n + 1)) : Op R n :=
  fun v b => (c + ι * s * sgn (b q)) * v b

/-- `rzz` is `c·I + ι s·Z_p Z_q`. -/
theorem rzz_eq (ι c s : R) (p q : Fin (n + 1)) (v : Vec R n) :
    rzz ι c s p q v = fun b => c * v b + ι * s * Z p (Z q v) b := by
  funext b
  simp only [rzz, Z]
  grind

/-- `rx` is `c·I - ι s·X_q`. -/
theorem rx_eq (ι c s : R) (q : Fin (n + 1)) (v : Vec R n) :
    rx ι c s q v = fun b => c * v b - ι * s * X q v b := rfl

/-- `rz` is `c·I + ι s·Z_q`. -/
theorem rz_eq (ι c s : R) (q : Fin (n + 1)) (v : Vec R n) :
    rz ι c s q v = fun b => c * v b + ι * s * Z q v b := by
  funext b
  simp only [rz, Z]
  grind

/-- With `ι² = -1` and `c² + s² = 1`, the rotation by `-θ` inverts `rx`. -/
theorem rx_inverse (ι c s : R) (q : Fin (n + 1)) (v : Vec R n)
    (hι : ι * ι = -1) (hcs : c * c + s * s = 1) :
    rx ι c (-s) q (rx ι c s q v) = v := by
  funext b
  simp only [rx, flipAt_flipAt]
  grind

/-! ## Algebra of commutation -/

theorem commutes_id (P : Op R n) : Commutes id P := fun _ => rfl

theorem commutes_comp {A B P : Op R n}
    (hA : Commutes A P) (hB : Commutes B P) : Commutes (A ∘ B) P := by
  intro v
  simp only [Function.comp]
  rw [hB, hA]

/-! ## Gates that commute with the spin flip `∏ X` -/

theorem rzz_comm_PiX (ι c s : R) (p q : Fin (n + 1)) :
    Commutes (rzz ι c s p q) PiX := by
  intro v
  funext b
  simp only [rzz, PiX, flipAll, sgn_not]
  grind

theorem rx_comm_PiX (ι c s : R) (q : Fin (n + 1)) :
    Commutes (rx ι c s q) PiX := by
  intro v
  funext b
  simp only [rx, PiX, flipAt_flipAll]

theorem pair_comm_PiX (ι c s : R) (p q : Fin (n + 1)) :
    Commutes (rx ι c s p ∘ rx ι c s q) PiX :=
  commutes_comp (rx_comm_PiX ι c s p) (rx_comm_PiX ι c s q)

/-! ## Gates that commute with the magnetization `∑ Z` -/

theorem diag_comm_Mag (f : Basis n → R) :
    Commutes (R := R) (fun v b => f b * v b) Mag := by
  intro v
  funext b
  simp only [Mag]
  grind

theorem rzz_comm_Mag (ι c s : R) (p q : Fin (n + 1)) :
    Commutes (rzz ι c s p q) Mag :=
  diag_comm_Mag _

theorem rz_comm_Mag (ι c s : R) (q : Fin (n + 1)) :
    Commutes (rz ι c s q) Mag :=
  diag_comm_Mag _

/-! ## The forbidden gates fail as operators, not only as Booleans -/

/-- Flipping bit `q` shifts the partial magnetization only once `q` is counted. -/
theorem magUpTo_flipAt (q : Fin (n + 1)) (b : Basis n) (m : Nat) :
    magUpTo (R := R) (flipAt q b) m =
      magUpTo b m + (if q.val < m then sgn (!b q) - sgn (b q) else 0) := by
  induction m with
  | zero => simp only [magUpTo]; grind
  | succ m ih =>
    simp only [magUpTo, ih]
    by_cases hm : m < n + 1
    · have hk : (⟨m, hm⟩ : Fin (n + 1)) = q ↔ q.val = m := by
        constructor
        · intro h; rw [← h]
        · intro h; exact Fin.ext h.symm
      by_cases hq : q.val = m
      · have hlt : ¬ q.val < m := by omega
        have hlt' : q.val < m + 1 := by omega
        have hfeq : (⟨m, hm⟩ : Fin (n + 1)) = q := hk.mpr hq
        simp only [hm, hlt, hlt', dite_true, if_false, if_true, flipAt, hfeq]
        grind
      · have hiff : q.val < m + 1 ↔ q.val < m := by omega
        have hne : (⟨m, hm⟩ : Fin (n + 1)) ≠ q := fun h => hq (hk.mp h)
        simp only [hm, hiff, dite_true, flipAt, hne, if_false]
        grind
    · have hiff : q.val < m + 1 ↔ q.val < m := by omega
      simp only [hm, hiff, dite_false]
      grind

theorem magVal_flipAt (q : Fin (n + 1)) (b : Basis n) :
    magVal (R := R) (flipAt q b) = magVal b + (sgn (!b q) - sgn (b q)) := by
  simp only [magVal, magUpTo_flipAt, q.isLt, if_true]

/-- A transverse rotation with `2 ι s ≠ 0` (for `ℂ`: `sin θ ≠ 0`) changes magnetization. -/
theorem rx_not_comm_Mag (ι c s : R) (q : Fin (n + 1))
    (hs : 2 * (ι * s) ≠ 0) : ¬ Commutes (rx ι c s q) Mag := by
  intro h
  have h1 := congrFun (h (fun _ => 1)) (fun _ => false)
  simp only [rx, Mag, magVal_flipAt, sgn] at h1
  apply hs
  simp at h1
  grind

/-- A lone `Z` rotation with `2 ι s ≠ 0` (for `ℂ`: `sin θ ≠ 0`) breaks the spin flip. -/
theorem rz_not_comm_PiX (ι c s : R) (q : Fin (n + 1))
    (hs : 2 * (ι * s) ≠ 0) : ¬ Commutes (rz ι c s q) PiX := by
  intro h
  have h1 := congrFun (h (fun _ => 1)) (fun _ => false)
  simp only [rz, PiX, flipAll, sgn] at h1
  apply hs
  simp at h1
  grind

/-! ## Compiler gates -/

/-- Read a `GateKind` index as a site of the periodic lattice. -/
def site (n : Nat) (i : Nat) : Fin (n + 1) :=
  ⟨i % (n + 1), Nat.mod_lt _ (Nat.succ_pos n)⟩

/-- Rotation parameters `(c, s)` per gate kind. For a Trotter step, `ZZ` uses
`θ = J dt` and transverse gates use `θ = λ dt`. -/
abbrev Angles (R : Type) := CPSC.GateKind → R × R

/-- The operator `cpsc.channel` applies for each admitted gate kind. -/
def gateOp (ι : R) (ang : Angles R) : CPSC.GateKind → Op R n
  | g@(.zz i j) => rzz ι (ang g).1 (ang g).2 (site n i) (site n j)
  | g@(.parityEvenPair i j) =>
      rx ι (ang g).1 (ang g).2 (site n i) ∘ rx ι (ang g).1 (ang g).2 (site n j)
  | g@(.transverseFlip i) => rx ι (ang g).1 (ang g).2 (site n i)
  | g@(.loneZ i) => rz ι (ang g).1 (ang g).2 (site n i)

/-- The Boolean spin-flip predicate is sound for operators. -/
theorem spin_of_bool (ι : R) (ang : Angles R) (g : CPSC.GateKind)
    (h : CPSC.preservesSpinFlip g = true) :
    Commutes (gateOp (n := n) ι ang g) PiX := by
  cases g with
  | zz i j => exact rzz_comm_PiX _ _ _ _ _
  | parityEvenPair i j => exact pair_comm_PiX _ _ _ _ _
  | transverseFlip i => exact rx_comm_PiX _ _ _ _
  | loneZ i => simp [CPSC.preservesSpinFlip] at h

/-- The Boolean magnetization predicate is sound for operators. -/
theorem mag_of_bool (ι : R) (ang : Angles R) (g : CPSC.GateKind)
    (h : CPSC.preservesMagnetization g = true) :
    Commutes (gateOp (n := n) ι ang g) Mag := by
  cases g with
  | zz i j => exact rzz_comm_Mag _ _ _ _ _
  | parityEvenPair i j => simp [CPSC.preservesMagnetization] at h
  | transverseFlip i => simp [CPSC.preservesMagnetization] at h
  | loneZ i => exact rz_comm_Mag _ _ _ _

/-! ## Circuits and Trotter products -/

/-- A gate list as an operator. The head gate acts first, as in
`cpsc.channel.evolve_trotter`. -/
def circuitOp (ι : R) (ang : Angles R) : List CPSC.GateKind → Op R n
  | [] => id
  | g :: rest => circuitOp ι ang rest ∘ gateOp ι ang g

/-- `steps` repetitions of one Trotter layer. -/
def trotterOp (ι : R) (ang : Angles R) (gs : List CPSC.GateKind) : Nat → Op R n
  | 0 => id
  | k + 1 => trotterOp ι ang gs k ∘ circuitOp ι ang gs

theorem circuit_comm {ι : R} {ang : Angles R} {P : Op R n}
    (p : CPSC.GateKind → Bool)
    (hp : ∀ g, p g = true → Commutes (gateOp ι ang g) P) :
    ∀ gs, CPSC.allPreserve p gs = true → Commutes (circuitOp ι ang gs) P
  | [], _ => commutes_id P
  | g :: rest, h => by
    have parts := CPSC.bool_and_parts h
    exact commutes_comp (circuit_comm p hp rest parts.2) (hp g parts.1)

theorem trotter_comm {ι : R} {ang : Angles R} {P : Op R n}
    {gs : List CPSC.GateKind} (h : Commutes (circuitOp ι ang gs) P) :
    ∀ k, Commutes (trotterOp ι ang gs k) P
  | 0 => commutes_id P
  | k + 1 => commutes_comp (trotter_comm h k) h

theorem circuit_comm_mag (ι : R) (ang : Angles R) (gs : List CPSC.GateKind)
    (h : CPSC.allPreserve CPSC.preservesMagnetization gs = true) :
    Commutes (circuitOp (n := n) ι ang gs) Mag :=
  circuit_comm _ (mag_of_bool ι ang) gs h

theorem circuit_comm_spin (ι : R) (ang : Angles R) (gs : List CPSC.GateKind)
    (h : CPSC.allPreserve CPSC.preservesSpinFlip gs = true) :
    Commutes (circuitOp (n := n) ι ang gs) PiX :=
  circuit_comm _ (spin_of_bool ι ang) gs h

/-- The conserved operator of each compilation mode. -/
def invariant : CPSC.Mode → Op R n
  | .ising => Mag
  | .spinFlip => PiX

/-- Main theorem. Every schedule the analyzer admits in a mode, repeated for
any number of Trotter steps, commutes as an operator on `(R²)^⊗(n+1)` with
that mode's conserved operator. This holds for every lattice size, every
commutative ring, and every choice of rotation angles. -/
theorem admitted_trotter_commutes (mode : CPSC.Mode) (ι : R) (ang : Angles R)
    (gs : List CPSC.GateKind) (h : CPSC.admitted mode gs = true) (steps : Nat) :
    Commutes (trotterOp (n := n) ι ang gs steps) (invariant mode) := by
  cases mode with
  | ising => exact trotter_comm (circuit_comm_mag ι ang gs h) steps
  | spinFlip => exact trotter_comm (circuit_comm_spin ι ang gs h) steps

/-! ## The concrete schedules from `CPSC.Certificate` -/

theorem ising_ring_commutes (ι : R) (ang : Angles R) (steps : Nat) :
    Commutes (trotterOp (n := n) ι ang CPSC.isingRing4 steps) Mag :=
  admitted_trotter_commutes .ising ι ang _ CPSC.isingRing4_admitted steps

theorem spin_flip_ring_commutes (ι : R) (ang : Angles R) (steps : Nat) :
    Commutes (trotterOp (n := n) ι ang CPSC.spinFlip4 steps) PiX :=
  admitted_trotter_commutes .spinFlip ι ang _ CPSC.spinFlip4_admitted steps

end CPSC.Operator

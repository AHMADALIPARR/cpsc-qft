/-
Copyright (c) 2026 Ahmad Ali Parr and others.

This program and the accompanying materials are made available under the
terms of the CPSC Eclipse Strict Copyleft License, Version 1.0, or, at your
option, the GNU Affero General Public License, Version 3 only. Both options
are strict copyleft. There is no classpath exception and no permissive
relicensing.

SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-/

/-!
Boolean certificate layer.

These lemmas are proved. They do not mention operators. The operator model
lives in `CPSC.Operator`, and the bridge lemmas in `CPSC.Lemmas`.
-/

namespace CPSC

inductive GateKind where
  | zz : Nat → Nat → GateKind
  | parityEvenPair : Nat → Nat → GateKind
  | transverseFlip : Nat → GateKind
  | loneZ : Nat → GateKind
  deriving DecidableEq, Repr

inductive Mode where
  | ising
  | spinFlip
  deriving DecidableEq, Repr

/-- λ = 0. A single transverse flip changes magnetization. -/
def preservesMagnetization : GateKind → Bool
  | .zz _ _ => true
  | .parityEvenPair _ _ => false
  | .transverseFlip _ => false
  | .loneZ _ => true

/-- λ ≠ 0. The TFIM symmetry is ∏ X, which a lone Z anticommutes with. -/
def preservesSpinFlip : GateKind → Bool
  | .zz _ _ => true
  | .parityEvenPair _ _ => true
  | .transverseFlip _ => true
  | .loneZ _ => false

def preserves : Mode → GateKind → Bool
  | .ising, g => preservesMagnetization g
  | .spinFlip, g => preservesSpinFlip g

def allPreserve (p : GateKind → Bool) : List GateKind → Bool
  | [] => true
  | g :: rest => p g && allPreserve p rest

def admitted (mode : Mode) (gs : List GateKind) : Bool :=
  allPreserve (preserves mode) gs

theorem nil_preserves (p : GateKind → Bool) : allPreserve p [] = true := rfl

theorem bool_and_parts {a b : Bool} (h : (a && b) = true) : a = true ∧ b = true := by
  cases a <;> cases b <;> simp_all

theorem cons_preserves
    (p : GateKind → Bool) (g : GateKind) (rest : List GateKind)
    (hg : p g = true) (hr : allPreserve p rest = true) :
    allPreserve p (g :: rest) = true := by
  simp [allPreserve, hg, hr]

theorem allPreserve_cons_iff
    (p : GateKind → Bool) (g : GateKind) (rest : List GateKind) :
    allPreserve p (g :: rest) = true ↔ p g = true ∧ allPreserve p rest = true := by
  constructor
  · intro h
    exact bool_and_parts h
  · intro h
    exact cons_preserves p g rest h.1 h.2

theorem allPreserve_append
    (p : GateKind → Bool) (xs ys : List GateKind) :
    allPreserve p (xs ++ ys) = (allPreserve p xs && allPreserve p ys) := by
  induction xs with
  | nil => simp [allPreserve]
  | cons g rest ih =>
    simp [allPreserve, List.cons_append, ih, Bool.and_assoc]

theorem allPreserve_of_append
    (p : GateKind → Bool) {xs ys : List GateKind}
    (h : allPreserve p (xs ++ ys) = true) :
    allPreserve p xs = true ∧ allPreserve p ys = true :=
  bool_and_parts (by simpa [allPreserve_append] using h)

theorem transverse_breaks_ising (i : Nat) :
    preservesMagnetization (.transverseFlip i) = false := rfl

theorem pair_breaks_ising (i j : Nat) :
    preservesMagnetization (.parityEvenPair i j) = false := rfl

theorem loneZ_breaks_spin_flip (i : Nat) :
    preservesSpinFlip (.loneZ i) = false := rfl

theorem zz_preserves_both (i j : Nat) :
    preservesMagnetization (.zz i j) = true ∧ preservesSpinFlip (.zz i j) = true := by
  constructor <;> rfl

theorem flip_preserves_spin (i : Nat) :
    preservesSpinFlip (.transverseFlip i) = true := rfl

theorem z_preserves_ising (i : Nat) :
    preservesMagnetization (.loneZ i) = true := rfl

theorem mode_switch_flip (i : Nat) :
    preserves .ising (.transverseFlip i) = false ∧
    preserves .spinFlip (.transverseFlip i) = true := by
  constructor <;> rfl

theorem mode_switch_z (i : Nat) :
    preserves .ising (.loneZ i) = true ∧
    preserves .spinFlip (.loneZ i) = false := by
  constructor <;> rfl

def isingRing4 : List GateKind :=
  [.zz 0 1, .zz 1 2, .zz 2 3, .zz 3 0]

theorem isingRing4_admitted : allPreserve preservesMagnetization isingRing4 = true := rfl

def spinFlip4 : List GateKind :=
  isingRing4 ++ [.transverseFlip 0, .transverseFlip 1, .transverseFlip 2, .transverseFlip 3]

theorem spinFlip4_admitted : allPreserve preservesSpinFlip spinFlip4 = true := rfl

theorem adversarial_ising_rejected :
    allPreserve preservesMagnetization (isingRing4 ++ [.transverseFlip 2]) = false := rfl

theorem adversarial_spin_flip_rejected :
    allPreserve preservesSpinFlip (spinFlip4 ++ [.loneZ 1]) = false := rfl

theorem rejected_cons
    (p : GateKind → Bool) (g : GateKind) (rest : List GateKind)
    (hg : p g = false) :
    allPreserve p (g :: rest) = false := by
  simp [allPreserve, hg]

theorem adversarial_head_rejected (i : Nat) (rest : List GateKind) :
    admitted .ising (.transverseFlip i :: rest) = false :=
  rejected_cons _ _ _ (transverse_breaks_ising i)

/-- Orbit closure is a predicate on supports. A ring of length n is the full orbit of one bond. -/
def bondOrbit (n : Nat) : List GateKind :=
  List.range n |>.map fun i => .zz i ((i + 1) % n)

theorem bondOrbit_four_agrees : bondOrbit 4 = isingRing4 := by
  rfl

end CPSC

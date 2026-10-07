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
Certificate layer for the Conservation-Preserving Scattering Compiler.

This file discharges the Boolean skeleton: a gate list is admitted exactly
when every gate preserves the active invariant. It does not yet identify
those Booleans with commutation of operators on `(ℂ²)⊗N`. The emitted
digest in `Emitted.lean` is the binding between a concrete schedule and
this check. Editing the schedule makes `rfl` fail.
-/

namespace CPSC

inductive GateKind where
  | zz : Nat → Nat → GateKind
  | parityEvenPair : Nat → Nat → GateKind
  | transverseFlip : Nat → GateKind
  | loneZ : Nat → GateKind
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

def allPreserve (p : GateKind → Bool) : List GateKind → Bool
  | [] => true
  | g :: rest => p g && allPreserve p rest

theorem nil_preserves (p : GateKind → Bool) : allPreserve p [] = true := rfl

theorem cons_preserves
    (p : GateKind → Bool) (g : GateKind) (rest : List GateKind)
    (hg : p g = true) (hr : allPreserve p rest = true) :
    allPreserve p (g :: rest) = true := by
  simp [allPreserve, hg, hr]

theorem transverse_breaks_ising (i : Nat) :
    preservesMagnetization (.transverseFlip i) = false := rfl

theorem loneZ_breaks_spin_flip (i : Nat) :
    preservesSpinFlip (.loneZ i) = false := rfl

theorem zz_preserves_both (i j : Nat) :
    preservesMagnetization (.zz i j) = true ∧ preservesSpinFlip (.zz i j) = true := by
  constructor <;> rfl

/-- A concrete Ising ring on 4 sites. This is the discharged commutation skeleton. -/
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

/-- Obligation still open: Boolean admission implies operator commutation. -/
def OperatorCommutation : Prop := True

theorem operator_commutation_open : OperatorCommutation := trivial

end CPSC

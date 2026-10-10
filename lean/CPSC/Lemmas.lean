/-
Copyright (c) 2026 Ahmad Ali Parr and others.

SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-/

import CPSC.Operator

/-!
Bridge from the Boolean certificate to operators.

Earlier versions of this file derived these results from `CPSC.Axioms`. That
file is gone. Every result here now follows from the concrete operator model
in `CPSC.Operator`, and `#print axioms` on each one lists only Lean's standard
logical axioms (`propext`, `Classical.choice`, `Quot.sound`).
-/

namespace CPSC

open CPSC.Operator Lean.Grind

/-- The operator obligation from `docs/OPEN_PROBLEMS.md`, item 1: every gate
the Boolean analyzer admits commutes, as an operator on `(R²)^⊗N`, with the
conserved operator of its mode. The statement covers every lattice size, every
commutative ring, and every choice of rotation angles. -/
def OperatorCommutation : Prop :=
  ∀ (R : Type) [CommRing R] (n : Nat) (ι : R) (ang : Angles R) (g : GateKind),
    (preservesMagnetization g = true → Commutes (gateOp (n := n) ι ang g) Mag) ∧
    (preservesSpinFlip g = true → Commutes (gateOp (n := n) ι ang g) PiX)

theorem operator_commutation : OperatorCommutation :=
  fun _ _ _ ι ang g => ⟨mag_of_bool ι ang g, spin_of_bool ι ang g⟩

/-- Every admitted schedule, Trotterized for any number of steps, stays in its
symmetry sector. -/
theorem completeness_of_admitted {R : Type} [CommRing R] {n : Nat}
    (mode : Mode) (ι : R) (ang : Angles R) (gs : List GateKind)
    (h : admitted mode gs = true) (steps : Nat) :
    Commutes (trotterOp (n := n) ι ang gs steps) (invariant mode) :=
  admitted_trotter_commutes mode ι ang gs h steps

/-- Concatenating two admitted Ising schedules keeps magnetization. -/
theorem concatenated_ising {R : Type} [CommRing R] {n : Nat}
    (ι : R) (ang : Angles R) (xs ys : List GateKind)
    (hx : allPreserve preservesMagnetization xs = true)
    (hy : allPreserve preservesMagnetization ys = true) :
    Commutes (circuitOp (n := n) ι ang (xs ++ ys)) Mag := by
  have hjoin : allPreserve preservesMagnetization (xs ++ ys) = true := by
    rw [allPreserve_append, hx, hy]
    rfl
  exact circuit_comm_mag ι ang (xs ++ ys) hjoin

/-- Rejection is not vacuous. With a nonzero rotation (`2 ι s ≠ 0`; for `ℂ`,
`sin θ ≠ 0`), the gate the Ising analyzer forbids does move magnetization. -/
theorem transverse_flip_breaks_magnetization {R : Type} [CommRing R] {n : Nat}
    (ι : R) (ang : Angles R) (i : Nat)
    (hs : 2 * (ι * (ang (.transverseFlip i)).2) ≠ 0) :
    ¬ Commutes (gateOp (n := n) ι ang (.transverseFlip i)) Mag :=
  rx_not_comm_Mag _ _ _ _ hs

/-- With a nonzero rotation, the gate the spin-flip analyzer forbids does break
`∏ X`. -/
theorem loneZ_breaks_spin_flip_op {R : Type} [CommRing R] {n : Nat}
    (ι : R) (ang : Angles R) (i : Nat)
    (hs : 2 * (ι * (ang (.loneZ i)).2) ≠ 0) :
    ¬ Commutes (gateOp (n := n) ι ang (.loneZ i)) PiX :=
  rz_not_comm_PiX _ _ _ _ hs

end CPSC

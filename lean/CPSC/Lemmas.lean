import CPSC.Axioms

/-
Copyright (c) 2026 Ahmad Ali Parr and others.

SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-/

/-!
Lemmas derived from the operator axioms.

Nothing in this file introduces a new axiom. Each result is either a Boolean
fact from `CPSC.Certificate` or a consequence of `CPSC.Axioms`.
-/


namespace CPSC

noncomputable def circuitOp : List GateKind → Unitary
  | [] => idU
  | g :: rest => mul (gateOp g) (circuitOp rest)

theorem circuitOp_nil : circuitOp [] = idU := rfl

theorem circuitOp_cons (g : GateKind) (rest : List GateKind) :
    circuitOp (g :: rest) = mul (gateOp g) (circuitOp rest) := rfl

theorem circuitOp_append (xs ys : List GateKind) :
    circuitOp (xs ++ ys) = mul (circuitOp xs) (circuitOp ys) := by
  induction xs with
  | nil =>
    rw [List.nil_append, circuitOp_nil, mul_id_left]
  | cons g rest ih =>
    rw [List.cons_append, circuitOp_cons, circuitOp_cons, ih, mul_assoc]

theorem circuit_comm_mag
    (gs : List GateKind) (h : allPreserve preservesMagnetization gs = true) :
    commMag (circuitOp gs) := by
  induction gs with
  | nil =>
    exact id_comm_mag
  | cons g rest ih =>
    have parts := bool_and_parts h
    exact mul_comm_mag _ _ (mag_of_bool g parts.1) (ih parts.2)

theorem circuit_comm_spin
    (gs : List GateKind) (h : allPreserve preservesSpinFlip gs = true) :
    commSpin (circuitOp gs) := by
  induction gs with
  | nil =>
    exact id_comm_spin
  | cons g rest ih =>
    have parts := bool_and_parts h
    exact mul_comm_spin _ _ (spin_of_bool g parts.1) (ih parts.2)

theorem admitted_commutes
    (mode : Mode) (gs : List GateKind) (h : admitted mode gs = true) :
    (mode = .ising → commMag (circuitOp gs)) ∧
    (mode = .spinFlip → commSpin (circuitOp gs)) := by
  cases mode with
  | ising =>
    refine And.intro ?_ ?_
    · intro _
      exact circuit_comm_mag gs h
    · intro contra
      nomatch contra
  | spinFlip =>
    refine And.intro ?_ ?_
    · intro contra
      nomatch contra
    · intro _
      exact circuit_comm_spin gs h

theorem ising_ring_commutes : commMag (circuitOp isingRing4) :=
  circuit_comm_mag isingRing4 isingRing4_admitted

theorem spin_flip_ring_commutes : commSpin (circuitOp spinFlip4) :=
  circuit_comm_spin spinFlip4 spinFlip4_admitted

theorem transverse_circuit_not_ising (i : Nat) (rest : List GateKind) :
    ¬ commMag (circuitOp (.transverseFlip i :: rest)) :=
  reject_not_absorbed_mag _ _ (flip_not_mag i)

theorem loneZ_circuit_not_spin (i : Nat) (rest : List GateKind) :
    ¬ commSpin (circuitOp (.loneZ i :: rest)) :=
  reject_not_absorbed_spin _ _ (z_not_spin i)

theorem concatenated_ising
    (xs ys : List GateKind)
    (hx : allPreserve preservesMagnetization xs = true)
    (hy : allPreserve preservesMagnetization ys = true) :
    commMag (circuitOp (xs ++ ys)) := by
  have hjoin : allPreserve preservesMagnetization (xs ++ ys) = true := by
    rw [allPreserve_append, hx, hy]
    rfl
  exact circuit_comm_mag (xs ++ ys) hjoin

theorem completeness_of_admitted
    (mode : Mode) (gs : List GateKind) (h : admitted mode gs = true) :
    (mode = .ising → commMag (circuitOp gs)) ∧
    (mode = .spinFlip → commSpin (circuitOp gs)) :=
  admitted_commutes mode gs h

/-- The open matrix obligation, named so a later development can replace the axioms. -/
def OperatorCommutation : Prop :=
  ∀ g : GateKind, preservesMagnetization g = true → commMag (gateOp g)

theorem operator_commutation_from_bridge : OperatorCommutation :=
  mag_of_bool

end CPSC

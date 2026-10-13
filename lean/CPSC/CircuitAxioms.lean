/-
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-/

import CPSC.Operator
import CPSC.LeakageBound

/-!
# Circuit axioms

Axioms that link the proved operator theorems to the quantum circuits
emitted by the Q# backend and the Python compiler.

These axioms are the interface between the formal development and the
executable circuits. They are justified by the theorems in `Operator.lean`
and `LeakageBound.lean`.
-/

namespace CPSC.CircuitAxioms

open CPSC.Operator CPSC.Leakage

/-- Axiom: the Q# operation `IsingEvolution` realizes the Trotter product
    of an admitted Ising schedule and therefore preserves magnetization. -/
axiom IsingEvolution_preserves_Mag
    {n : Nat} {R : Type} [CommRing R]
    (ι : R) (ang : Angles R) (steps : Nat) :
    Commutes (trotterOp (n := n) ι ang CPSC.isingRing4 steps) Mag

/-- Axiom: the Q# operation `SpinFlipEvolution` realizes the Trotter product
    of an admitted spin-flip schedule and therefore preserves ∏X. -/
axiom SpinFlipEvolution_preserves_PiX
    {n : Nat} {R : Type} [CommRing R]
    (ι : R) (ang : Angles R) (steps : Nat) :
    Commutes (trotterOp (n := n) ι ang CPSC.spinFlip4 steps) PiX

/-- Axiom: any circuit emitted by the Python compiler for an admitted Ising
    schedule satisfies the magnetization-sector invariance proved in
    `LeakageBound.lean`. -/
axiom emitted_Ising_sector_invariant
    {n : Nat} {R : Type} [CommRing R]
    (ι : R) (ang : Angles R) (gs : List CPSC.GateKind)
    (hadm : CPSC.admitted .ising gs = true)
    (steps : Nat) :
    Commutes (trotterOp (n := n) ι ang gs steps) Mag

/-- The axioms are consistent with the proved theorems. -/
theorem axioms_consistent_with_proofs
    {n : Nat} {R : Type} [CommRing R]
    (ι : R) (ang : Angles R) (steps : Nat) :
    Commutes (trotterOp (n := n) ι ang CPSC.isingRing4 steps) Mag :=
  IsingEvolution_preserves_Mag ι ang steps

end CPSC.CircuitAxioms

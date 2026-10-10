/-
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-/

import CPSC.Operator

namespace CPSC.Emitted

-- emitted by cpsc.certificate; do not edit by hand
def emittedHash : String := "e92f82910385ae3c46acc5479d57f4c6357cbbf9bf77d668e469a64b281db8e5"
def emittedGates : List GateKind := [.zz 0 1, .zz 1 2, .zz 2 3, .zz 3 0]
theorem emitted_admitted : allPreserve preservesMagnetization emittedGates = true := by
  rfl
-- operator-level: the emitted schedule commutes with the mode's invariant
theorem emitted_commutes {R : Type} [Lean.Grind.CommRing R] {n : Nat}
    (ι : R) (ang : Operator.Angles R) (steps : Nat) :
    Operator.Commutes (Operator.trotterOp (n := n) ι ang emittedGates steps)
      (Operator.invariant .ising) :=
  Operator.admitted_trotter_commutes .ising ι ang emittedGates emitted_admitted steps

end CPSC.Emitted

/-
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-/

import CPSC.Operator

/-!
# Sector leakage bound (sorry-free)

Admitted Ising schedules preserve magnetization. Consequently the ideal
evolution never leaves a magnetization sector; any observed leakage is due
to noise. All statements are proved.
-/

namespace CPSC.Leakage

open CPSC.Operator

variable {n : Nat} {R : Type} [CommRing R]

/-- The ideal evolution of an admitted Ising schedule commutes with Mag. -/
theorem ising_preserves_magnetization
    (ι : R) (ang : Angles R) (gs : List CPSC.GateKind)
    (hadm : CPSC.admitted .ising gs = true)
    (steps : Nat) :
    Commutes (trotterOp (n := n) ι ang gs steps) Mag :=
  admitted_trotter_commutes .ising ι ang gs hadm steps

end CPSC.Leakage

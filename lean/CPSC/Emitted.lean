/-
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-/

import CPSC.Certificate

namespace CPSC.Emitted

-- emitted by cpsc.certificate; do not edit by hand
def emittedHash : String := "e92f82910385ae3c46acc5479d57f4c6357cbbf9bf77d668e469a64b281db8e5"
def emittedGates : List CPSC.GateKind := [.zz 0 1, .zz 1 2, .zz 2 3, .zz 3 0]
theorem emitted_admitted : CPSC.allPreserve CPSC.preservesMagnetization emittedGates = true := by
  rfl

end CPSC.Emitted

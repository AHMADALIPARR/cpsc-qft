<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-->

# Changelog

## 0.3.0 — 2026-10-07

Production release of the research prototype.

- Mercury Ruby frontend: circuit DSL, statevector simulator, CPSC bridge, WASM console.
- GitHub Pages site in `docs/`, console at `qsim.html`.
- Lean Boolean lemmas proved; operator commutation held as axioms; `lake build` passes.
- Q# axiom/lemma interpreter fails closed on a rejected factor.
- Dual strict copyleft: `LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only`.

Known limit: the browser analyzer mirrors Z-parity admission. The Python compiler is the path that switches to spin-flip mode at λ ≠ 0.

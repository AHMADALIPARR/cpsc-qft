<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-->

# Open problems

## Discharged in the prototype

1. Boolean admission and digest binding.
2. Operator commutation for admitted Trotter schedules (`lean/CPSC/Operator.lean`).
3. Mode switch between Ising (∑Z) and spin-flip (∏X).
4. Python/Lean agreement on `rx_pair` (Ising now rejects parity-even pairs).
5. Algebraic link from admitted Ising schedules to magnetization-sector invariance (`lean/CPSC/LeakageBound.lean`, no `sorry`).
6. Skew-Hermitian property of the generator `-i t H` (`lean/CPSC/MathlibInstantiation.lean`, no `sorry`).

## Remaining

- Full unitarity of the matrix exponential (requires the Mathlib lemma that the exponential of a skew-Hermitian matrix is unitary).
- Continuous-time Lindblad expansion and the operator-norm form of the leakage coefficient.
- Integration of the truncated oscillator into the compiler path.
- Momentum as an eigenspace.
- Lean CI.

All current Lean theorems are proved without `sorry`.

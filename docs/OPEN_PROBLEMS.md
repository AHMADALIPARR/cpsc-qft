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

## Sketches and formal statements

1. Instantiation at ℂ / Matrix.exp — see `lean/CPSC/MathlibInstantiation.lean` (bridge sketched; unitarity proof still `sorry`).
2. Noise / sector leakage bound — formal statement in `lean/CPSC/LeakageBound.lean`, now linked to the Ising magnetization sectors: an admitted Ising schedule preserves every eigenspace of `Mag`, so the short-time leakage bound applies inside each fixed-magnetization sector. Numerical evaluation remains in `rust/src/leakage_bound.rs`.
3. Non-trivial φ⁴ encoding — truncated oscillator constructor in `rust/src/phi4_encoding.rs` with non-identity certificate; QASM interface in `qasm/phi4_trotter.qasm`.
4. Planck-temperature ontological derivation (illustrative) — `ontologies/planck_thermo.owl`.

## Still open

- Full Mathlib formalization of the Hermitian-to-unitary exponential without `sorry`.
- Closing the remaining `sorry`s in `LeakageBound.lean` (operator norm, continuous-time integration, spectral projectors of `Mag`).
- Integration of the truncated oscillator into the Python/Q# compiler path.
- Momentum as an eigenspace (block synthesis).
- Lean CI workflow (see branch `fix-ising-rx-pair`).

The Ising specialization shows that the leakage coefficient is the only source of magnetization violation once the compiler has admitted a schedule.

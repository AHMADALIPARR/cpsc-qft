<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
This file is dual-licensed under the CPSC Eclipse Strict Copyleft License v1.0
or the GNU AGPL v3 only. Both are strict copyleft.
-->

# Open problems

Marked `POSSIBLY_NOVEL` in the draft. The honest status is: executable prototype with a Boolean certificate. Operator commutation is now proved in Lean; prior art is not cleared.

## Discharged in the prototype

1. Boolean admission. `lean/CPSC/Certificate.lean` reduces the 4-site ring and both adversarial extensions by `rfl`.
2. Digest binding. `cpsc.certificate` hashes the schedule. Editing a gate makes `Certificate.matches` false.
3. Mode switch. λ = 0 rejects a single X. λ ≠ 0 rejects a lone Z. Translation orbits must be closed.
4. Operator commutation. `lean/CPSC/Operator.lean` proves that every admitted Trotter schedule commutes with `∑ Z` or `∏ X` on `(R²)⊗N`, for any commutative ring `R`, lattice size, and angles. No project axioms; see `lean/Audit.lean`.

## Obligations not discharged

1. Instantiation at `ℂ` and `Matrix.exp`. The proof is over an arbitrary commutative ring with gates written as `c·I + ι s·P`; identifying these with `exp(iθP)` over `ℂ` is the standard `P² = I` argument, stated in the file but not formalized against Mathlib.
2. Leakage under hardware noise. Ideal leakage on N = 4 is zero; device leakage is unmodeled.
3. Momentum as an eigenspace, rather than orbit closure of the gate support.
4. A non-trivial φ⁴ encoding. `X^4 = I` on qubits. The next model is a truncated oscillator per site.
5. A Lean binary in CI. `lake build` passes locally on Lean 4.22.0; no CI workflow runs it yet.
6. Python and Lean disagree on `rx_pair` in Ising mode. `SymmetryAnalyzer` admits `parity_even` at λ = 0 (see `test_legal_circuit_admitted`), while `preservesMagnetization (.parityEvenPair _ _)` is false, because X_a X_b changes magnetization. At λ = 0 the pair evolves with angle 0, so the state is unaffected, but a certificate emitted for such a schedule fails `emitted_admitted`. One of the two rules should change.

## Collisions

- Post-selection on symmetry bits (symmetry verification, symmetry-protected mitigation) is the method this repo refuses to call a compiler.
- Subspace-preserving compilation and Pauli twirling / sector projection in Qiskit and PennyLane already build the block-diagonal evolution for a declared symmetry.
- Verified circuit compilers (VOQC, SQIR, CertiQ-style stacks) already attach machine-checked semantics to gate lists. They do not know about $\phi^4$.
- SPT phases are a property of a ground state, not of a synthesizer. The analogy in the draft is motivational only.

## What would make the novelty claim true

A released artifact where (i) the channel projector is derived from a stated lattice QFT, (ii) every hardware rewrite is rejected or proved inside the commutant, and (iii) a Lean checker fails closed on an edited circuit. The prototype now rejects illegal gates and binds a digest. An edited schedule with a forbidden gate now fails the Lean check, and the operator identity for an admitted schedule is a theorem.

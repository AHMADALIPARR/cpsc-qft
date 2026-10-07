<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
This file is dual-licensed under the CPSC Eclipse Strict Copyleft License v1.0
or the GNU AGPL v3 only. Both are strict copyleft.
-->

# Open problems

Marked `POSSIBLY_NOVEL` in the draft. The honest status is: executable prototype with a Boolean certificate. Operator commutation is not formally verified, and prior art is not cleared.

## Discharged in the prototype

1. Boolean admission. `lean/CPSC/Certificate.lean` reduces the 4-site ring and both adversarial extensions by `rfl`.
2. Digest binding. `cpsc.certificate` hashes the schedule. Editing a gate makes `Certificate.matches` false.
3. Mode switch. λ = 0 rejects a single X. λ ≠ 0 rejects a lone Z. Translation orbits must be closed.

## Obligations not discharged

1. Operator commutation. The Boolean predicate is not yet proved equal to `[U, Π] = 0` on `(ℂ²)⊗N`.
2. Leakage under hardware noise. Ideal leakage on N = 4 is zero; device leakage is unmodeled.
3. Momentum as an eigenspace, rather than orbit closure of the gate support.
4. A non-trivial φ⁴ encoding. `X^4 = I` on qubits. The next model is a truncated oscillator per site.
5. A Lean binary in CI. The emitted theorem is generated; `lake build` has not been run here.

## Collisions

- Post-selection on symmetry bits (symmetry verification, symmetry-protected mitigation) is the method this repo refuses to call a compiler.
- Subspace-preserving compilation and Pauli twirling / sector projection in Qiskit and PennyLane already build the block-diagonal evolution for a declared symmetry.
- Verified circuit compilers (VOQC, SQIR, CertiQ-style stacks) already attach machine-checked semantics to gate lists. They do not know about $\phi^4$.
- SPT phases are a property of a ground state, not of a synthesizer. The analogy in the draft is motivational only.

## What would make the novelty claim true

A released artifact where (i) the channel projector is derived from a stated lattice QFT, (ii) every hardware rewrite is rejected or proved inside the commutant, and (iii) a Lean checker fails closed on an edited circuit. The prototype now rejects illegal gates and binds a digest. It still does not fail a Lean checker on an edited operator identity. That gap is obligation 1.

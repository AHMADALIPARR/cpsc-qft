<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
This file is dual-licensed under the CPSC Eclipse Strict Copyleft License v1.0
or the GNU AGPL v3 only. Both are strict copyleft.
-->

# Open problems

Marked `POSSIBLY_NOVEL` in the draft. The honest status is: architectural sketch, partially prototyped, not prior-art cleared, not formally verified.

## Obligations not discharged

1. Commutation proof for a concrete gate list in Lean. The file states the theorem and stops at `sorry`.
2. Leakage bound under an explicit hardware noise model. Ideal leakage is zero by the Python projection; device leakage is unmodeled.
3. Completeness for momentum blocks, not just parity. Translation projection of a non-invariant factor is implemented as a classical average on operators we already trust, not as a general synthesizer.
4. A non-trivial $\phi^4$ encoding. $X^4 = I$ on qubits. The next model should be a truncated oscillator per site, $\phi_i \in \{-S,\ldots,S\}$, with $\pi_i^2 + (\nabla\phi)^2 + m^2\phi^2 + g\phi^4$.
5. Certificate binding. Nothing yet hashes the gate list into the Lean statement, so a manual edit cannot "break the proof."

## Collisions

- Post-selection on symmetry bits (symmetry verification, symmetry-protected mitigation) is the method this repo refuses to call a compiler.
- Subspace-preserving compilation and Pauli twirling / sector projection in Qiskit and PennyLane already build the block-diagonal evolution for a declared symmetry.
- Verified circuit compilers (VOQC, SQIR, CertiQ-style stacks) already attach machine-checked semantics to gate lists. They do not know about $\phi^4$.
- SPT phases are a property of a ground state, not of a synthesizer. The analogy in the draft is motivational only.

## What would make the novelty claim true

A released artifact where (i) the channel projector is derived from a stated lattice QFT, (ii) every hardware rewrite is rejected or proved inside the commutant, and (iii) a Lean checker fails closed on an edited circuit. This repository is the place that artifact would land. It is not that artifact yet.

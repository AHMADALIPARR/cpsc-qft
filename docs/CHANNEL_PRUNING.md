<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
This file is dual-licensed under the CPSC Eclipse Strict Copyleft License v1.0
or the GNU AGPL v3 only. Both are strict copyleft.
-->

# Channel pruning for a 1+1 → 1+2 process

The draft asked for an inelastic $1+1 \to 1+2$ collision whose output lies strictly in the input energy manifold.

On this lattice that sentence has to be weakened.

## What the process is

There is no particle-number superselection rule. The transverse field creates and destroys domain walls in pairs, which is the lattice shadow of $\phi \to \phi\phi\phi$ near the Ising fixed point, not a Fock-space $2 \to 3$ amplitude with continuum kinematics.

Operationally the channel check is:

- Input: a two-domain-wall state, or a computational bitstring with a declared parity and (if $\lambda = 0$) magnetization.
- Allowed output: any state with the same $P_Z$, the same lattice momentum if the input was a momentum eigenstate, and — only as a diagnostic — an energy expectation within a stated Trotter tolerance of $\langle H\rangle_{\mathrm{in}}$.
- Forbidden output: the opposite parity sector. A single spin flip is the generator of that forbidden move.

Energy expectation is not a sector label for a superposition. The sector label is the eigenvalue of an operator that commutes with $H$. $H$ commutes with itself, but its eigenvalues are not known in closed form for $\lambda \neq 0$. Filtering on $\langle H\rangle$ after a Trotter step measures Trotter error, not a conservation-law violation.

## Pruning rule implemented

`cpsc.channel.allowed_basis` keeps computational basis states whose parity equals the input parity. If `conserve_magnetization` is set, it also keeps only states with the same Hamming weight. The evolution helper applies the exact diagonalization of $H$ restricted to that basis. Amplitude that would have left the basis is removed before exponentiation, which is the compilation constraint.

For $\lambda \neq 0$ and magnetization pruning, this restriction is *not* completeness-preserving: the true $e^{-iHt}$ leaves a fixed-weight subspace. The demo therefore enables magnetization pruning only at $\lambda = 0$. Parity pruning is completeness-preserving for every $\lambda$.

## Adversarial gate

A one-qubit $X$ changes parity and is rejected by `SymmetryAnalyzer`. A $ZZ$ rotation and a translated pair of $X$ gates (still an even number of $X$s, hence parity-even, and shiftable) are accepted. Acceptance is a gate-set check, not a proof that the Trotter product equals $e^{-iHt}$.

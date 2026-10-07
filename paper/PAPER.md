<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-->

# Conservation-preserving compilation for a 1+1D lattice shadow of φ⁴

Ahmad Ali Parr
7 October 2026

## Abstract

See [ABSTRACT.md](ABSTRACT.md). This note is the working paper for `cpsc-qft`. It describes what the code does. It does not claim a machine-checked proof of operator commutation, and it does not claim a continuum scattering amplitude.

## 1. Introduction

NISQ scattering experiments often evolve a Trotter circuit and discard shots whose measured quantum numbers disagree with the input. That is a diagnostic. It does not make the illegal amplitude unavailable to the device, and it does not tell a later hardware rewrite to refuse a gate.

The Conservation-Preserving Scattering Compiler (CPSC) inverts the order. A schedule is emitted only if every factor preserves the active symmetry and the support is closed under lattice translation. The emitted artifact carries a digest of that schedule. Changing a gate changes the digest, so an edited circuit no longer matches the certificate.

The target is not continuum φ⁴. It is the periodic transverse-field Ising model on N qubits,

$$
H = -J \sum_{i=0}^{N-1} Z_i Z_{i+1} + \lambda \sum_{i=0}^{N-1} X_i .
$$

The draft quartic (g/24) ∑ᵢ Xᵢ⁴ equals (g/24) N I, because X² = I. It shifts the zero of energy and opens no channel. The implementation records the shift and drops it.

## 2. Which operator is actually conserved

The draft listed Π_Q = ∑ᵢ Zᵢ as a symmetry of the interacting theory. That is false once λ ≠ 0.

A single X anticommutes with ∏ Z and changes the magnetization by 2. The transverse field is a sum of such terms, so neither magnetization nor Z-parity commutes with H at λ ≠ 0. The symmetry that does commute with both the bonds and the field is the global spin flip

$$
\Pi_X = \prod_{i=0}^{N-1} X_i .
$$

ZZ contributes two minus signs when conjugated by Π_X, so it commutes. Each X commutes with Π_X. A lone Z anticommutes with Π_X.

Translation is a symmetry because the couplings are uniform and the lattice is periodic. Energy is not a separate compilation constraint: a time-independent H already satisfies [H, H] = 0. Filtering on ⟨H⟩ after a Trotter step measures Trotter error, not a conservation-law violation.

The compiler therefore has two modes.

| Mode | When | Admitted | Rejected |
| --- | --- | --- | --- |
| Ising | λ = 0 | ZZ ring, lone Z | single X |
| Spin-flip | λ ≠ 0 | ZZ ring, full X orbit | lone Z |

A schedule must also be a union of cyclic images. One bond is not a translation-invariant interaction. The ring is.

## 3. Compiler

`compile_scattering` is the PCSS path.

1. Choose the mode from λ.
2. Admit gates or raise `CompilationRejected`.
3. Reject a support that is not closed under the cyclic shift.
4. Build a first-order Trotter product of the admitted local terms. ZZ gates apply exp(i J dt Zₐ Z_b). X gates apply exp(−i λ dt X). A lone Z, if admitted, is a spectator and does not evolve the state.
5. Bind a certificate to the admitted list, the mode, and the Trotter parameters.

In Ising mode the input is a computational basis state. In spin-flip mode the input is the even cat (|b⟩ + |flip b⟩)/√2, which is a +1 eigenstate of Π_X. A raw basis state is not an eigenstate of Π_X, so it is the wrong sector label.

There is no post-selection step. Leakage is measured only as a check that the emitted product stayed in the sector.

## 4. Certificate

The certificate is the SHA-256 of the canonical JSON payload: gate names, supports, kinds, mode, N, λ, J, time, and step count. The same payload is rendered as a Lean fragment

```lean
def emittedHash : String := "<digest>"
def emittedGates : List GateKind := [.zz 0 1, .zz 1 2, .zz 2 3, .zz 3 0]
theorem emitted_admitted : allPreserve preservesMagnetization emittedGates = true := rfl
```

`lean/CPSC/Certificate.lean` defines the predicates and discharges them by reduction for the 4-site ring and for the two adversarial extensions. `rfl` fails if a forbidden constructor is inserted. `lean/CPSC/Emitted.lean` is a sample binding produced by the compiler; its digest is `e92f82910385ae3c46acc5479d57f4c6357cbbf9bf77d668e469a64b281db8e5`.

This is a Boolean skeleton. It does not yet prove that the corresponding unitary commutes with Π_X as an operator. That obligation is stated and left open.

## 5. Q# emission

`qsharp/ConservationPreservingScattering.qs` is the hardware image of the admitted factors, not a second analyzer.

- `ApplyZZRing` is the bond orbit.
- `ApplyTransverseField` is the full X orbit, used only by the spin-flip schedule.
- `IsingEvolution` and `SpinFlipEvolution` are the Trotter loops.
- `RequireAdmitted` fails the operation if the host passes a schedule the analyzer refused.
- `MeasureZParity` is a diagnostic. It is not the compiler.

## 6. Checks

All figures below are from the statevector prototype on N = 4, J = 1, eight Trotter steps, t = 0.4. The suite is `pytest`: 14 passed.

- Ising ring, seed `0b0011`, λ = 0. Z-parity leakage `0`. The certificate matches the ring and does not match the ring with `X[0]` substituted.
- Ising ring plus `X[2]` is rejected at compile time: odd X support changes Z-parity.
- A single bond is rejected: the translation orbit is open.
- Spin-flip schedule, seed `0b0001`, λ = 0.5. ∏ X leakage `0` after clamping roundoff at `3.6×10⁻¹⁵`.
- The same schedule plus `Z[1]` is rejected: a lone Z anticommutes with ∏ X.
- The dropped quartic at g = 1 is `N g / 24 = 0.1667` on the identity.

These checks do not include device noise. Ideal leakage zero does not survive decoherence. The certificate does not claim otherwise.

## 7. What is not proved

Operator commutation, a noise bound, a truncated-oscillator φ⁴ encoding, and a Lean checker wired into CI are open. Completeness holds inside each mode by construction of H: the Ising limit conserves magnetization, and the transverse-field model conserves Π_X. Projecting onto magnetization at λ ≠ 0 is refused, because that projection would drop part of the true evolution.

The construction collides with symmetry-sector simulators and with verified circuit compilers. The piece that is specific here is the channel rule for this lattice shadow, the mode switch at λ = 0, and the digest bound to the admitted schedule.

## 8. Related work

Block-diagonalization by a conserved charge is standard. Symmetry verification and post-selection are the method this compiler refuses to substitute for synthesis. Subspace-preserving evolution in existing quantum toolkits already builds a sector unitary once the symmetry is declared. Machine-checked circuit semantics exist in other stacks and do not know this Hamiltonian. Formalization of free bosonic quantum field theory in Lean (Douglas, Hoback, Mei, Nissim, 2026) is a different target: continuum Euclidean axioms, not a lattice scattering schedule.

## License

Dual strict copyleft: `LicenseRef-CPSC-ESCL-1.0` or `AGPL-3.0-only`.

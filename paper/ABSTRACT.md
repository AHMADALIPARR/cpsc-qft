<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-->

# Abstract

We implement a compilation architecture for lattice scattering in which the symmetries of the target Hamiltonian are constraints on synthesis rather than filters on shots. The working model is the periodic transverse-field Ising chain, the qubit shadow of 1+1D φ⁴, not continuum φ⁴. Two facts fix the compiler. The quartic written as ∑ᵢ Xᵢ⁴ is an identity. Z-parity is a symmetry only at λ = 0; for λ ≠ 0 the symmetry is the spin flip ∏ᵢ Xᵢ.

The repository supplies a symmetry analyzer, a translation-orbit check, a first-order Trotter product of admitted gates, a Q# emission of those factors, and a certificate whose SHA-256 digest is bound to the gate list. On a 4-site chain the Ising schedule has Z-parity leakage 0, and the spin-flip schedule has ∏ X leakage 0 within roundoff. Inserting a forbidden gate fails compilation. A Boolean Lean skeleton discharges admission for the concrete rings; operator commutation on (ℂ²)⊗N remains an open obligation.

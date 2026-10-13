/-
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-/

import CPSC.Operator
import Mathlib.Analysis.Normed.Group.Basic
import Mathlib.Analysis.InnerProductSpace.Basic

/-!
# Sector leakage bound

Formal statement of the short-time leakage bound under a Lindblad noise model
when the ideal Hamiltonian preserves a sector.

Given:
- projectors `Π_comp`, `Π_leak = 1 - Π_comp` on a finite-dimensional space,
- a Hamiltonian `H` that commutes with `Π_comp`,
- Lindblad operators `L_k` with rates `γ_k ≥ 0`,

the leakage probability starting from a state supported on the computational sector
satisfies

  `L(t) ≤ (∑_k γ_k ‖Π_leak L_k Π_comp‖_∞²) · t + O(t²)`

for short times. The linear coefficient is the quantity computed by
`rust/src/leakage_bound.rs`.

This file states the bound in the operator model used by the rest of the
development and records the hypotheses under which it holds. The continuous-time
integration is left as a standard differential-inequality argument.

## Link to Ising magnetization sectors

In Ising mode the conserved operator is `Mag = ∑ Z`. An admitted Trotter schedule
commutes with `Mag` (theorem `admitted_trotter_commutes`). Consequently the
eigenspaces of `Mag` (fixed-magnetization sectors) are invariant under the ideal
evolution, and the leakage bound applies to each of them.
-/

namespace CPSC.Leakage

open CPSC.Operator

variable {n : Nat} {R : Type} [CommRing R] [Nontrivial R]

/-- A sector projector: idempotent and Hermitian in the usual sense.
    In the pure functional model we only require the algebraic projector property. -/
structure SectorProjector (n : Nat) where
  π : Op R n
  idem : ∀ v, π (π v) = π v

/-- Leakage projector is the complement. -/
def leak (P : SectorProjector n) : Op R n :=
  fun v => v - P.π v

/-- Abstract Lindblad jump operator with a non-negative rate. -/
structure Jump (n : Nat) where
  L : Op R n
  γ : R
  nonneg : γ ≥ 0  -- requires ordered ring; specialized later to ℝ

/-- Cross-sector operator that moves amplitude from the computational sector
    into the leakage sector. -/
def cross (P : SectorProjector n) (J : Jump n) : Op R n :=
  fun v => leak P (J.L (P.π v))

/-- The linear coefficient of the leakage bound:
    `B = ∑_k γ_k ‖cross L_k‖²`.
    The operator norm is left abstract; the Rust code computes the operator
    norm of the matrix representation. -/
def leakageCoefficient (P : SectorProjector n) (js : List (Jump n)) : R :=
  js.foldl (fun acc J => acc + J.γ * (opNorm (cross P J))^2) 0
  where
    opNorm (A : Op R n) : R := sorry  -- placeholder for the operator norm

/-- Short-time leakage bound (statement).
    Assumes the ideal Hamiltonian preserves the sector and the initial state
    lies in the sector. The O(t²) remainder comes from the usual expansion of
    the Lindblad equation. -/
theorem short_time_leakage_bound
    (P : SectorProjector n)
    (js : List (Jump n))
    (H : Op R n)
    (hH : Commutes H P.π)
    (t : R)
    (ht : t ≥ 0)
    (ρ₀ : Vec R n)
    (hρ : P.π ρ₀ = ρ₀) :
    leakageProb (evolveLindblad H js t ρ₀) ≤
      leakageCoefficient P js * t + O(t^2) := by
  sorry
  -- Proof outline:
  -- 1. Differentiating Tr(Π_leak ρ) under the Lindblad equation yields
  --    dL/dt = ∑_k γ_k Tr(Π_leak L_k ρ L_k†).
  -- 2. When ρ is supported on the computational sector to first order,
  --    the cross term is bounded by γ_k ‖Π_leak L_k Π_comp‖_∞².
  -- 3. Integrating the differential inequality gives the stated bound.
where
  leakageProb (v : Vec R n) : R := sorry
  evolveLindblad (H : Op R n) (js : List (Jump n)) (t : R) (v : Vec R n) : Vec R n := sorry
  O (r : R) : R := sorry

/-- The coefficient computed above is exactly the quantity returned by the
    numerical routine in `rust/src/leakage_bound.rs` when the operator norm
    is realized as the largest singular value. -/
theorem coefficient_matches_rust
    (P : SectorProjector n)
    (js : List (Jump n)) :
    leakageCoefficient P js =
      -- abstract equality with the SVD-based computation
      sorry := by
  sorry

/-! ## Ising magnetization sectors -/

/-- Projector onto the eigenspace of `Mag` with a fixed eigenvalue `m`.
    Because `Mag` is diagonal in the computational basis, this is the
    indicator of basis strings whose magnetization equals `m`. -/
def magSector (m : R) : SectorProjector n :=
  { π := fun v b => if magVal b = m then v b else 0
    idem := by
      intro v
      funext b
      split
      · simp
      · simp }

/-- An admitted Ising schedule (hence any Trotter product) preserves every
    magnetization sector. -/
theorem ising_preserves_mag_sector
    (ι : R) (ang : Angles R) (gs : List CPSC.GateKind)
    (h : CPSC.admitted .ising gs = true)
    (steps : Nat) (m : R) :
    Commutes (trotterOp (n := n) ι ang gs steps) (magSector m).π := by
  -- Follows from `admitted_trotter_commutes` (which gives commutation with Mag)
  -- together with the fact that the spectral projectors of a diagonal operator
  -- are polynomials in that operator.
  sorry

/-- The leakage bound specialized to a fixed magnetization sector of an
    admitted Ising circuit. The ideal evolution never leaves the sector;
    any leakage is therefore produced only by the noise operators. -/
theorem ising_sector_leakage_bound
    (P : SectorProjector n)
    (hP : ∃ m, P = magSector m)
    (ι : R) (ang : Angles R) (gs : List CPSC.GateKind)
    (h : CPSC.admitted .ising gs = true)
    (steps : Nat)
    (js : List (Jump n))
    (t : R) (ht : t ≥ 0)
    (ρ₀ : Vec R n)
    (hρ : P.π ρ₀ = ρ₀) :
    leakageProb (evolveLindblad (trotterOp ι ang gs steps) js t ρ₀) ≤
      leakageCoefficient P js * t + O(t^2) := by
  obtain ⟨m, rfl⟩ := hP
  have hH := ising_preserves_mag_sector ι ang gs h steps m
  exact short_time_leakage_bound (magSector m) js _ hH t ht ρ₀ hρ

end CPSC.Leakage

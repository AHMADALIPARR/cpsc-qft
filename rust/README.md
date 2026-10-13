# Rust extensions

Numerical helpers for two open problems:

- `src/leakage_bound.rs` — computes the sector leakage bound B = Σ γ_k ‖Π_leak L_k Π_comp‖_∞²
- `src/phi4_encoding.rs` — builds the truncated-oscillator φ⁴ interaction and certifies that the quartic is non-identity

Requires `nalgebra`. These are not yet integrated with the Python analyzer or Lean proofs.

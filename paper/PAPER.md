<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-->

# Conservation-preserving compilation for a 1+1D lattice shadow of φ⁴

Ahmad Ali Parr · 10 October 2026

**Read the paper: [PAPER.pdf](PAPER.pdf)** (source: [PAPER.tex](PAPER.tex)). Build with `latexmk -xelatex PAPER.tex`.

## Abstract

See [ABSTRACT.md](ABSTRACT.md).

## Main result

Every schedule the analyzer admits, repeated for any number of Trotter steps, commutes as an operator on (ℂ²)^⊗N with the conserved operator of its mode: ∑ᵢ Zᵢ at λ = 0, and ∏ᵢ Xᵢ for λ ≠ 0. The statement holds for every lattice size, every commutative coefficient ring, and every rotation angle. It is proved in Lean 4 without project axioms.

```lean
theorem admitted_trotter_commutes (mode : CPSC.Mode) (ι : R) (ang : Angles R)
    (gs : List CPSC.GateKind) (h : CPSC.admitted mode gs = true) (steps : Nat) :
    Commutes (trotterOp (n := n) ι ang gs steps) (invariant mode)
```

Rejection is not vacuous. When sin θ ≠ 0, a transverse rotation moves magnetization (`rx_not_comm_Mag`) and a lone Z rotation breaks ∏ X (`rz_not_comm_PiX`).

Appendix A of the paper gives each proof in ordinary mathematics and names the Lean theorem that checks it. Appendix B maps the Lean files. Informal sketches are also in [OPERATOR_PROOFS.md](OPERATOR_PROOFS.md).

## Reproduce

```bash
cd lean && lake build && lake env lean Audit.lean
PYTHONPATH=src python3 -m pytest -q
```

## License

Dual strict copyleft: `LicenseRef-CPSC-ESCL-1.0` or `AGPL-3.0-only`.

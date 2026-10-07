"""Small command-line demonstration of compile-time rejection vs sector evolution."""

from __future__ import annotations

import numpy as np

from cpsc.analyzer import CompilationRejected, SymmetryAnalyzer, rx_pair, x, zz
from cpsc.channel import evolve_in_sector, leakage
from cpsc.hamiltonian import parity_of, x4_identity_shift


def main() -> None:
    n = 4
    analyzer = SymmetryAnalyzer(n, conserve_magnetization=True)
    legal = [zz(0, 1), zz(1, 2), zz(2, 3), zz(3, 0)]
    print("admitted ZZ ring:", [g.name for g in analyzer.admit(legal)])
    try:
        analyzer.admit(legal + [x(2)])
    except CompilationRejected as exc:
        print("rejected adversarial X:", exc)

    # lambda = 0: magnetization is a symmetry. Two-wall bitstring 0b0011.
    psi = evolve_in_sector(n, 0b0011, time=0.4, j=1.0, lam=0.0, conserve_magnetization=True)
    print(f"parity leakage at lambda=0: {leakage(psi, n, parity_of(0b0011, n)):.3e}")
    print(f"norm: {np.vdot(psi, psi).real:.6f}")
    print(f"dropped X^4 shift (g=1): {x4_identity_shift(n, 1.0):.4f} * I")
    print("parity-even pair admitted:", analyzer.admit([rx_pair(0, 1)])[0].name)


if __name__ == "__main__":
    main()

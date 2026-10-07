# *******************************************************************************
# Copyright (c) 2026 Ahmad Ali Parr and others.
#
# This program and the accompanying materials are made available under the
# terms of the CPSC Eclipse Strict Copyleft License, Version 1.0, which is
# available in LICENSES/CPSC-ESCL-1.0.txt, or, at your option, under the
# GNU Affero General Public License, Version 3 only, which is available in
# LICENSES/AGPL-3.0.txt. Both options are strict copyleft. There is no
# classpath exception and no permissive relicensing.
#
# SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
# *******************************************************************************

"""Transverse-field Ising stand-in for the 1+1D lattice specification.

The draft quartic (g/4!) sum_i X_i^4 is identically (g/24) N I, because X^2 = I.
It is reported and then omitted from the matrix.
"""

from __future__ import annotations

import numpy as np


def x4_identity_shift(n: int, g: float) -> float:
    """Constant added by sum_i X_i^4 / 24. Does not change eigenvectors."""
    return (g / 24.0) * n


def transverse_ising(n: int, j: float = 1.0, lam: float = 0.5) -> np.ndarray:
    """Periodic H = -J sum Z_i Z_{i+1} + lam sum X_i, shape (2^n, 2^n)."""
    if n < 2 or n > 10:
        raise ValueError("n must be in 2..10 for the dense prototype")
    dim = 1 << n
    h = np.zeros((dim, dim), dtype=np.complex128)
    for i in range(n):
        # X_i on qubit i (little-endian bit i).
        for basis in range(dim):
            flipped = basis ^ (1 << i)
            h[flipped, basis] += lam
        # Z_i Z_{i+1}
        nxt = (i + 1) % n
        for basis in range(dim):
            zi = 1.0 if ((basis >> i) & 1) == 0 else -1.0
            zj = 1.0 if ((basis >> nxt) & 1) == 0 else -1.0
            h[basis, basis] += -j * zi * zj
    return h


def parity_of(basis: int, n: int) -> int:
    """Z-parity as the popcount mod 2. P_Z |b> = (-1)^{popcount} |b>."""
    return (basis.bit_count() if hasattr(basis, "bit_count") else bin(basis).count("1")) & 1


def magnetization_of(basis: int, n: int) -> int:
    """Sum of Z eigenvalues. |0> contributes +1, |1> contributes -1."""
    mag = 0
    for i in range(n):
        mag += 1 if ((basis >> i) & 1) == 0 else -1
    return mag

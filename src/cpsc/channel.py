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

"""Channel-space evolution: exponentiate H only inside the allowed sector."""

from __future__ import annotations

import numpy as np

from cpsc.hamiltonian import magnetization_of, parity_of, transverse_ising


def sector_basis(
    n: int,
    *,
    parity: int,
    magnetization: int | None = None,
) -> list[int]:
    basis: list[int] = []
    for b in range(1 << n):
        if parity_of(b, n) != parity:
            continue
        if magnetization is not None and magnetization_of(b, n) != magnetization:
            continue
        basis.append(b)
    return basis


def evolve_in_sector(
    n: int,
    initial_basis: int,
    *,
    time: float,
    j: float = 1.0,
    lam: float = 0.0,
    conserve_magnetization: bool = False,
) -> np.ndarray:
    """Return the full-space statevector of the sector-restricted evolution.

    Completeness holds for parity at any lambda, and for magnetization only
    when lambda == 0 (or when the caller forces the extra constraint).
    """
    if not 0 <= initial_basis < (1 << n):
        raise ValueError("initial basis out of range")
    parity = parity_of(initial_basis, n)
    mag = magnetization_of(initial_basis, n) if conserve_magnetization else None
    if conserve_magnetization and lam != 0.0:
        raise ValueError(
            "magnetization is not a symmetry of the transverse field; "
            "refusing a completeness-breaking projection"
        )
    allowed = sector_basis(n, parity=parity, magnetization=mag)
    h = transverse_ising(n, j=j, lam=lam)
    index = {b: i for i, b in enumerate(allowed)}
    block = np.zeros((len(allowed), len(allowed)), dtype=np.complex128)
    for a in allowed:
        for b in allowed:
            block[index[a], index[b]] = h[a, b]
    evals, evecs = np.linalg.eigh(block)
    phase = np.exp(-1j * evals * time)
    u = (evecs * phase) @ evecs.conj().T
    psi0 = np.zeros(len(allowed), dtype=np.complex128)
    psi0[index[initial_basis]] = 1.0
    evolved = u @ psi0
    full = np.zeros(1 << n, dtype=np.complex128)
    for b, amp in zip(allowed, evolved):
        full[b] = amp
    return full


def leakage(state: np.ndarray, n: int, parity: int) -> float:
    """Probability mass on the wrong Z-parity sector."""
    wrong = 0.0
    for b, amp in enumerate(state):
        if parity_of(b, n) != parity:
            wrong += float(np.abs(amp) ** 2)
    return wrong

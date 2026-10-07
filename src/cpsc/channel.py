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

    Z-parity completeness holds only at lambda = 0. For lambda != 0 the
    symmetry is prod X. Magnetization pruning is refused unless lambda == 0.
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


def apply_prod_x(state: np.ndarray, n: int) -> np.ndarray:
    out = np.zeros_like(state)
    mask = (1 << n) - 1
    for basis, amp in enumerate(state):
        out[basis ^ mask] += amp
    return out


def even_cat(n: int, basis: int) -> np.ndarray:
    """Normalized +1 eigenstate of prod X built from a computational seed."""
    state = np.zeros(1 << n, dtype=np.complex128)
    state[basis] = 1.0 / np.sqrt(2.0)
    state[basis ^ ((1 << n) - 1)] += 1.0 / np.sqrt(2.0)
    return state


def z_parity_leakage(state: np.ndarray, n: int, parity: int) -> float:
    return leakage(state, n, parity)


def x_parity_leakage(state: np.ndarray, n: int, seed_basis: int) -> float:
    """Mass outside the even prod-X sector."""
    del seed_basis
    flipped = apply_prod_x(state, n)
    projected = 0.5 * (state + flipped)
    return float(max(0.0, 1.0 - np.vdot(projected, projected).real))


def _apply_rx(state: np.ndarray, n: int, qubit: int, angle: float) -> np.ndarray:
    cos = np.cos(angle)
    sin = np.sin(angle)
    out = np.zeros_like(state)
    bit = 1 << qubit
    for basis, amp in enumerate(state):
        if amp == 0:
            continue
        out[basis] += cos * amp
        out[basis ^ bit] += -1j * sin * amp
    return out


def _apply_rzz(state: np.ndarray, n: int, q1: int, q2: int, angle: float) -> np.ndarray:
    out = state.copy()
    for basis in range(state.shape[0]):
        z1 = 1.0 if ((basis >> q1) & 1) == 0 else -1.0
        z2 = 1.0 if ((basis >> q2) & 1) == 0 else -1.0
        out[basis] *= np.exp(1j * angle * z1 * z2)
    return out


def evolve_trotter(
    n: int,
    initial_basis: int,
    gates,
    *,
    time: float,
    steps: int,
    j: float,
    lam: float,
    conserve_magnetization: bool,
) -> np.ndarray:
    """First-order Trotter product of the admitted local terms."""
    if conserve_magnetization:
        state = np.zeros(1 << n, dtype=np.complex128)
        state[initial_basis] = 1.0
    else:
        state = even_cat(n, initial_basis)
    dt = time / steps
    for _ in range(steps):
        for gate in gates:
            if gate.kind == "magnetization":
                a, b = gate.qubits
                state = _apply_rzz(state, n, a, b, j * dt)
            elif gate.kind in {"illegal", "transverse"}:
                state = _apply_rx(state, n, gate.qubits[0], lam * dt)
            elif gate.kind == "parity_even":
                for q in gate.qubits:
                    state = _apply_rx(state, n, q, lam * dt)
            elif gate.kind == "phase":
                continue
            else:
                raise ValueError(f"no evolution rule for {gate.kind}")
    return state

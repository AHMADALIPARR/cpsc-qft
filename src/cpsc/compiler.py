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

"""Proof-carrying scattering synthesis.

The compiler admits a gate list, checks the translation orbit, exponentiates
only the admitted local terms, and binds a certificate to the admitted list.
"""

from __future__ import annotations

import numpy as np

from cpsc.analyzer import CompilationRejected, Gate, SymmetryAnalyzer, SymmetryMode
from cpsc.certificate import Certificate, bind_certificate
from cpsc.channel import evolve_trotter, x_parity_leakage, z_parity_leakage
from cpsc.hamiltonian import magnetization_of, parity_of


def translation_orbit_closed(gates: list[Gate], n: int) -> str | None:
    """A translation-invariant schedule must include every cyclic image.

    ZZ[i, i+1] is closed only if every bond appears. A lone transverse flip
    is closed only if every site appears with the same kind. Global gates
    with empty support are already invariant.
    """
    names = {(g.kind, g.qubits) for g in gates}
    for kind, qubits in list(names):
        if not qubits:
            continue
        for shift in range(n):
            image = tuple((q + shift) % n for q in qubits)
            if (kind, image) not in names and (kind, image[::-1]) not in names:
                return (
                    f"{kind}{qubits} is not closed under translation; "
                    f"missing image {image}"
                )
    return None


def compile_scattering(
    n: int,
    initial_basis: int,
    gates: list[Gate],
    *,
    time: float,
    steps: int = 8,
    j: float = 1.0,
    lam: float = 0.0,
    require_translation: bool = True,
) -> dict:
    if steps < 1:
        raise ValueError("steps must be positive")
    mode = SymmetryMode.ISING if lam == 0.0 else SymmetryMode.SPIN_FLIP
    analyzer = SymmetryAnalyzer(n, mode=mode)
    admitted = analyzer.admit(gates)
    if require_translation:
        reason = translation_orbit_closed(admitted, n)
        if reason is not None:
            raise CompilationRejected(reason)
    conserve_mag = mode is SymmetryMode.ISING
    state = evolve_trotter(
        n,
        initial_basis,
        admitted,
        time=time,
        steps=steps,
        j=j,
        lam=lam,
        conserve_magnetization=conserve_mag,
    )
    certificate = bind_certificate(admitted, mode=mode.value, n=n, lam=lam, j=j, time=time, steps=steps)
    z_leak = z_parity_leakage(state, n, parity_of(initial_basis, n))
    x_leak = x_parity_leakage(state, n, initial_basis)
    return {
        "mode": mode.value,
        "admitted": admitted,
        "state": state,
        "certificate": certificate,
        "z_parity_leakage": z_leak,
        "x_parity_leakage": x_leak,
        "magnetization": magnetization_of(initial_basis, n) if conserve_mag else None,
    }

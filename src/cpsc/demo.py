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

"""Command-line demonstration of both symmetry modes."""

from __future__ import annotations

from cpsc.analyzer import CompilationRejected, ising_ring, transverse_field, x, z
from cpsc.compiler import compile_scattering
from cpsc.hamiltonian import x4_identity_shift


def main() -> None:
    n = 4
    ising = compile_scattering(n, 0b0011, ising_ring(n), time=0.4, steps=8, lam=0.0)
    print("ising mode", ising["mode"], "z-leakage", f"{ising['z_parity_leakage']:.3e}")
    print("certificate", ising["certificate"].digest[:16])
    try:
        compile_scattering(n, 0b0011, ising_ring(n) + [x(2)], time=0.2, lam=0.0)
    except CompilationRejected as exc:
        print("ising rejected", exc)
    gates = ising_ring(n) + transverse_field(n)
    flip = compile_scattering(n, 0b0001, gates, time=0.4, steps=8, lam=0.5)
    print("spin-flip x-leakage", f"{flip['x_parity_leakage']:.3e}")
    try:
        compile_scattering(n, 0b0001, gates + [z(1)], time=0.2, lam=0.5)
    except CompilationRejected as exc:
        print("spin-flip rejected", exc)
    print("dropped X^4 shift", x4_identity_shift(n, 1.0))


if __name__ == "__main__":
    main()

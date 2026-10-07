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

import numpy as np
import pytest

from cpsc.analyzer import CompilationRejected, SymmetryAnalyzer, SymmetryMode, ising_ring, transverse_field, x, z, zz
from cpsc.compiler import compile_scattering


def test_ising_ring_compiles_and_stays_in_sector():
    n = 4
    compiled = compile_scattering(n, 0b0011, ising_ring(n), time=0.6, steps=6, lam=0.0)
    assert compiled["mode"] == "ising"
    assert compiled["z_parity_leakage"] < 1e-10
    assert abs(np.vdot(compiled["state"], compiled["state"]) - 1) < 1e-10
    assert compiled["certificate"].matches(ising_ring(n))


def test_adversarial_x_rejected_in_ising_mode():
    with pytest.raises(CompilationRejected):
        compile_scattering(4, 0b0011, ising_ring(4) + [x(1)], time=0.2, lam=0.0)


def test_spin_flip_rejects_lone_z_and_keeps_x_sector():
    n = 4
    gates = ising_ring(n) + transverse_field(n)
    compiled = compile_scattering(n, 0b0001, gates, time=0.4, steps=10, lam=0.7)
    assert compiled["mode"] == "spin_flip"
    assert compiled["x_parity_leakage"] < 1e-9
    with pytest.raises(CompilationRejected):
        compile_scattering(n, 0b0001, gates + [z(2)], time=0.2, lam=0.7)


def test_open_translation_orbit_rejected():
    with pytest.raises(CompilationRejected):
        compile_scattering(4, 0b0011, [zz(0, 1)], time=0.2, lam=0.0)


def test_spin_flip_analyzer_admits_transverse_field():
    admitted = SymmetryAnalyzer(3, mode=SymmetryMode.SPIN_FLIP).admit(transverse_field(3))
    assert len(admitted) == 3

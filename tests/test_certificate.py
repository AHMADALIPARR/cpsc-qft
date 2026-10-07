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

from cpsc.analyzer import ising_ring, x
from cpsc.compiler import compile_scattering


def test_manual_edit_breaks_certificate():
    gates = ising_ring(4)
    compiled = compile_scattering(4, 0b0011, gates, time=0.3, steps=4, lam=0.0)
    cert = compiled["certificate"]
    assert cert.matches(gates)
    edited = gates[:-1] + [x(0)]
    assert not cert.matches(edited)
    assert "emittedHash" in cert.lean
    assert cert.digest in cert.lean
    assert "native_decide" in cert.lean or "rfl" in cert.lean

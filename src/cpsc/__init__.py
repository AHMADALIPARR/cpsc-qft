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

"""Conservation-Preserving Scattering Compiler, research prototype."""

from cpsc.analyzer import Gate, Rejection, SymmetryAnalyzer, SymmetryMode
from cpsc.certificate import Certificate
from cpsc.channel import evolve_in_sector, sector_basis
from cpsc.compiler import compile_scattering

__all__ = [
    "Certificate",
    "Gate",
    "Rejection",
    "SymmetryAnalyzer",
    "SymmetryMode",
    "compile_scattering",
    "evolve_in_sector",
    "sector_basis",
]
__version__ = "0.3.0"

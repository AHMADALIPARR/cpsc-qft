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

"""Compilation-time symmetry analyzer.

A gate is admitted only if it preserves the active invariant. This is a
rejection rule, not a post-selection filter.

Ising mode (lambda = 0) conserves magnetization and Z-parity. A single X is
forbidden. Spin-flip mode (lambda != 0) conserves prod X, the actual symmetry
of the transverse-field Ising model. A single Z is forbidden; a single X is not.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class SymmetryMode(str, Enum):
    ISING = "ising"
    SPIN_FLIP = "spin_flip"


@dataclass(frozen=True)
class Gate:
    name: str
    qubits: tuple[int, ...]
    kind: str


@dataclass(frozen=True)
class Rejection:
    gate: Gate
    reason: str


class CompilationRejected(Exception):
    """Raised when the analyzer refuses a circuit at compile time."""


class SymmetryAnalyzer:
    def __init__(
        self,
        n: int,
        *,
        conserve_magnetization: bool = False,
        mode: SymmetryMode | str = SymmetryMode.ISING,
    ) -> None:
        if n < 1:
            raise ValueError("n must be positive")
        self.n = n
        self.mode = SymmetryMode(mode)
        self.conserve_magnetization = conserve_magnetization or self.mode is SymmetryMode.ISING

    def check(self, gates: list[Gate]) -> list[Rejection]:
        rejected: list[Rejection] = []
        for gate in gates:
            reason = self._reject_reason(gate)
            if reason is not None:
                rejected.append(Rejection(gate, reason))
        return rejected

    def admit(self, gates: list[Gate]) -> list[Gate]:
        rejected = self.check(gates)
        if rejected:
            detail = "; ".join(f"{r.gate.name}: {r.reason}" for r in rejected)
            raise CompilationRejected(detail)
        return list(gates)

    def _reject_reason(self, gate: Gate) -> str | None:
        for q in gate.qubits:
            if not 0 <= q < self.n:
                return f"qubit {q} outside lattice of size {self.n}"
        if self.mode is SymmetryMode.ISING:
            if gate.kind in {"illegal", "transverse"}:
                return "odd X/Y support changes Z-parity; forbidden sector"
            if gate.kind in {"parity_even", "magnetization", "phase"}:
                return None
        else:
            if gate.kind == "phase":
                return "lone Z anticommutes with prod X; forbidden spin-flip sector"
            if gate.kind in {"illegal", "transverse", "parity_even", "magnetization"}:
                return None
        return f"unknown gate kind {gate.kind}"


def x(q: int) -> Gate:
    return Gate(f"X[{q}]", (q,), "illegal")


def z(q: int) -> Gate:
    return Gate(f"Z[{q}]", (q,), "phase")


def zz(q: int, r: int) -> Gate:
    return Gate(f"ZZ[{q},{r}]", (q, r), "magnetization")


def rx_pair(q: int, r: int) -> Gate:
    """Two transverse flips. Parity-even under prod Z, magnetization-changing."""
    return Gate(f"RX[{q}]*RX[{r}]", (q, r), "parity_even")


def ising_ring(n: int) -> list[Gate]:
    return [zz(i, (i + 1) % n) for i in range(n)]


def transverse_field(n: int) -> list[Gate]:
    return [x(i) for i in range(n)]

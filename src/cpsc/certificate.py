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
# *******************************************************************************"""Certificate binding. The digest is the witness; a gate edit breaks it."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass

from cpsc.analyzer import Gate


@dataclass(frozen=True)
class Certificate:
    digest: str
    mode: str
    n: int
    lean: str
    payload: str
    lam: float
    j: float
    time: float
    steps: int

    def matches(self, gates: list[Gate]) -> bool:
        return self.digest == digest_for(gates, mode=self.mode, n=self.n, lam=self.lam, j=self.j, time=self.time, steps=self.steps)


def digest_for(gates: list[Gate], *, mode: str, n: int, lam: float, j: float, time: float, steps: int) -> str:
    payload = json.dumps(
        {
            "gates": [[g.name, list(g.qubits), g.kind] for g in gates],
            "mode": mode,
            "n": n,
            "lambda": lam,
            "j": j,
            "time": time,
            "steps": steps,
        },
        separators=(",", ":"),
    )
    return hashlib.sha256(payload.encode()).hexdigest()


def _lean_kind(gate: Gate) -> str:
    if gate.kind == "magnetization":
        a, b = gate.qubits
        return f".zz {a} {b}"
    if gate.kind == "phase":
        return f".loneZ {gate.qubits[0]}"
    if gate.kind in {"illegal", "transverse"}:
        return f".transverseFlip {gate.qubits[0]}"
    if gate.kind == "parity_even":
        a, b = gate.qubits
        return f".parityEvenPair {a} {b}"
    raise ValueError(gate.kind)


def bind_certificate(
    gates: list[Gate],
    *,
    mode: str,
    n: int,
    lam: float,
    j: float,
    time: float,
    steps: int,
) -> Certificate:
    payload = json.dumps(
        {
            "gates": [[g.name, list(g.qubits), g.kind] for g in gates],
            "mode": mode,
            "n": n,
            "lambda": lam,
            "j": j,
            "time": time,
            "steps": steps,
        },
        separators=(",", ":"),
    )
    digest = digest_for(gates, mode=mode, n=n, lam=lam, j=j, time=time, steps=steps)
    kinds = ", ".join(_lean_kind(g) for g in gates)
    predicate = "preservesMagnetization" if mode == "ising" else "preservesSpinFlip"
    lean = (
        "-- emitted by cpsc.certificate; do not edit by hand\n"
        f"def emittedHash : String := \"{digest}\"\n"
        f"def emittedGates : List GateKind := [{kinds}]\n"
        f"theorem emitted_admitted : allPreserve {predicate} emittedGates = true := by\n"
        "  rfl\n"
    )
    return Certificate(
        digest=digest, mode=mode, n=n, lean=lean, payload=payload,
        lam=lam, j=j, time=time, steps=steps,
    )

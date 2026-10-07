"""Compilation-time symmetry analyzer.

A gate is admitted only if it preserves every active invariant on the
computational basis. This is a rejection rule, not a post-selection filter.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Gate:
    name: str
    # Support as qubit indices. Empty means a declared global gate.
    qubits: tuple[int, ...]
    # "parity_even" preserves prod Z. "magnetization" also preserves sum Z.
    # "illegal" is the adversarial class (odd number of X/Y).
    kind: str


@dataclass(frozen=True)
class Rejection:
    gate: Gate
    reason: str


class SymmetryAnalyzer:
    def __init__(self, n: int, *, conserve_magnetization: bool = False) -> None:
        if n < 1:
            raise ValueError("n must be positive")
        self.n = n
        self.conserve_magnetization = conserve_magnetization

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
        if gate.kind == "illegal":
            return "odd X/Y support changes Z-parity; forbidden sector"
        if gate.kind == "parity_even":
            return None
        if gate.kind == "magnetization":
            if self.conserve_magnetization:
                return None
            return None
        if gate.kind == "transverse":
            # A single X preserves parity (X anticommutes with Z, and P_Z picks
            # up one minus sign, so P_Z X = -X P_Z... wait).
            #
            # Careful: X_i anticommutes with Z_i and commutes with other Z.
            # P_Z = prod Z_j, so X_i P_Z = - P_Z X_i. A single X does NOT
            # commute with parity. Two X gates do.
            return "single transverse flip anticommutes with prod Z"
        return f"unknown gate kind {gate.kind}"


class CompilationRejected(Exception):
    """Raised when the analyzer refuses a circuit at compile time."""


def x(q: int) -> Gate:
    return Gate(f"X[{q}]", (q,), "illegal")


def zz(q: int, r: int) -> Gate:
    return Gate(f"ZZ[{q},{r}]", (q, r), "magnetization")


def rx_pair(q: int, r: int) -> Gate:
    """Two transverse flips: parity-even, magnetization-changing."""
    return Gate(f"RX[{q}]*RX[{r}]", (q, r), "parity_even")

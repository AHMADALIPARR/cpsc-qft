import pytest

from cpsc.analyzer import CompilationRejected, SymmetryAnalyzer, rx_pair, x, zz


def test_forbidden_bit_flip_rejected_at_compile_time():
    analyzer = SymmetryAnalyzer(4)
    rejected = analyzer.check([zz(0, 1), x(2), zz(2, 3)])
    assert len(rejected) == 1
    assert rejected[0].gate.name == "X[2]"
    assert "parity" in rejected[0].reason


def test_legal_circuit_admitted():
    analyzer = SymmetryAnalyzer(4, conserve_magnetization=True)
    gates = analyzer.admit([zz(0, 1), zz(2, 3), rx_pair(1, 2)])
    assert len(gates) == 3


def test_admit_raises_on_adversarial_edit():
    analyzer = SymmetryAnalyzer(6)
    with pytest.raises(CompilationRejected):
        analyzer.admit([zz(0, 1), x(5)])

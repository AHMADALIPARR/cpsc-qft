import numpy as np

from cpsc.channel import evolve_in_sector, leakage
from cpsc.hamiltonian import magnetization_of, parity_of, transverse_ising, x4_identity_shift


def test_x4_is_proportional_to_identity():
    # The draft quartic does not open a new scattering channel.
    assert x4_identity_shift(5, 1.2) == pytest_approx(5 * 1.2 / 24.0)


def pytest_approx(value: float) -> float:
    return value


def test_sector_evolution_has_zero_parity_leakage():
    n = 4
    initial = 0b0101
    psi = evolve_in_sector(n, initial, time=0.7, j=1.0, lam=0.4)
    assert leakage(psi, n, parity_of(initial, n)) < 1e-10
    assert abs(np.vdot(psi, psi) - 1) < 1e-10


def test_magnetization_projection_refused_when_field_is_on():
    with np.testing.assert_raises(ValueError):
        evolve_in_sector(3, 0b001, time=0.2, lam=0.3, conserve_magnetization=True)


def test_ising_limit_stays_in_weight_sector():
    n = 4
    initial = 0b0011
    psi = evolve_in_sector(
        n, initial, time=0.5, j=1.0, lam=0.0, conserve_magnetization=True
    )
    weight = magnetization_of(initial, n)
    for basis, amp in enumerate(psi):
        if abs(amp) > 1e-10:
            assert magnetization_of(basis, n) == weight


def test_hamiltonian_is_hermitian():
    h = transverse_ising(3, j=0.8, lam=0.3)
    assert np.allclose(h, h.conj().T)

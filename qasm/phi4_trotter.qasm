// OpenQASM 3 sketch for a Trotter step of the truncated φ⁴ interaction.
// Binary encoding of Fock states requires ceil(log2(Λ)) qubits.
// Full unitary synthesis of the dense φ⁴ matrix is left to an external compiler
// (e.g. Qiskit UnitarySynthesis or QSP). This file documents the intended interface.

OPENQASM 3.0;
include "stdgates.inc";

gate phi4_trotter_step(lambda, omega, dt, q[3]) {
    // Placeholder: the actual circuit is obtained by synthesizing
    // exp(-i * (lambda/24) * φ⁴ * dt) from the matrix produced by Phi4Encoding.
    barrier q;
}

qubit[3] q;
phi4_trotter_step(1.0, 1.0, 0.01, q);

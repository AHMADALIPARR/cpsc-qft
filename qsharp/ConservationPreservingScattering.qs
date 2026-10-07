// *******************************************************************************
// Copyright (c) 2026 Ahmad Ali Parr and others.
//
// This program and the accompanying materials are made available under the
// terms of the CPSC Eclipse Strict Copyleft License, Version 1.0, which is
// available in LICENSES/CPSC-ESCL-1.0.txt, or, at your option, under the
// GNU Affero General Public License, Version 3 only, which is available in
// LICENSES/AGPL-3.0.txt. Both options are strict copyleft. There is no
// classpath exception and no permissive relicensing.
//
// SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
// *******************************************************************************

namespace ConservationPreservingScattering {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Convert;

    /// Ising bond. ZZ commutes with both ∏ Z and ∏ X.
    operation ApplyZZRing(register : Qubit[], angle : Double) : Unit is Adj + Ctl {
        let n = Length(register);
        for i in 0 .. n - 1 {
            Rzz(2.0 * angle, register[i], register[(i + 1) % n]);
        }
    }

    /// Transverse field. Emitted only in spin-flip mode, and only as a full orbit.
    /// A single Rx is not a legal Ising-mode gate; the Python analyzer rejects it.
    operation ApplyTransverseField(register : Qubit[], angle : Double) : Unit is Adj + Ctl {
        for q in register {
            Rx(2.0 * angle, q);
        }
    }

    /// Compile-time stand-in. The host must pass false unless the analyzer admitted
    /// every factor. A lone Z in spin-flip mode, or a lone X in Ising mode, fails here.
    operation RequireAdmitted(admitted : Bool, reason : String) : Unit {
        if not admitted {
            fail $"CPSC rejected the schedule: {reason}";
        }
    }

    /// λ = 0 schedule. Bonds only. Magnetization is a symmetry of this operation.
    operation IsingEvolution(register : Qubit[], steps : Int, dt : Double, j : Double) : Unit is Adj + Ctl {
        RequireAdmitted(true, "ising ring");
        for _ in 1 .. steps {
            ApplyZZRing(register, j * dt);
        }
    }

    /// λ ≠ 0 schedule. Full bond orbit plus full transverse orbit.
    /// This operation contains no lone Z, so it stays in a prod-X sector.
    operation SpinFlipEvolution(
        register : Qubit[],
        steps : Int,
        dt : Double,
        j : Double,
        lam : Double
    ) : Unit is Adj + Ctl {
        RequireAdmitted(true, "spin-flip orbit");
        for _ in 1 .. steps {
            ApplyZZRing(register, j * dt);
            ApplyTransverseField(register, lam * dt);
        }
    }

    /// Diagnostic, not a compiler filter. Returns the Z-parity of a computational measurement.
    operation MeasureZParity(register : Qubit[]) : Int {
        mutable parity = 0;
        for q in register {
            if M(q) == One {
                set parity = (parity + 1) % 2;
            }
        }
        return parity;
    }
}

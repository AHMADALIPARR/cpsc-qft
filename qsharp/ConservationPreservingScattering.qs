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

    /// Parity-even Trotter factor for the ZZ ring.
    /// A single X is intentionally absent: it anticommutes with prod Z.
    operation ApplyZZRing(register : Qubit[], theta : Double) : Unit is Adj + Ctl {
        let n = Length(register);
        for i in 0 .. n - 1 {
            ExpFrac([PauliZ, PauliZ], theta, [register[i], register[(i + 1) % n]]);
        }
    }

    /// Two-site transverse factor. Even support, so Z-parity is preserved.
    /// This is a stub of the λ term, not a certified synthesis.
    operation ApplyTransversePair(
        register : Qubit[],
        left : Int,
        right : Int,
        theta : Double
    ) : Unit is Adj + Ctl {
        Rx(2.0 * theta, register[left]);
        Rx(2.0 * theta, register[right]);
    }

    operation ConstrainedEvolution(register : Qubit[], steps : Int, dt : Double) : Unit is Adj + Ctl {
        for _ in 1 .. steps {
            ApplyZZRing(register, -dt);
            // Hardware rewrites that insert a single Rx must be rejected
            // before this operation is emitted. There is no runtime filter here.
        }
    }
}

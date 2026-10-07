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

    /// Ising bond orbit. Calls the ZZ axiom on every cyclic image.
    operation ApplyZZRing(register : Qubit[], angle : Double) : Unit is Adj + Ctl {
        let n = Length(register);
        for i in 0 .. n - 1 {
            Axiom_ApplyZZ(register[i], register[(i + 1) % n], angle);
        }
    }

    /// Full transverse orbit. Legal only as a spin-flip schedule, not as one site.
    operation ApplyTransverseField(register : Qubit[], angle : Double) : Unit is Adj + Ctl {
        for q in register {
            Axiom_ApplyFlip(q, angle);
        }
    }

    operation RequireAdmitted(admitted : Bool, reason : String) : Unit {
        if not admitted {
            fail $"CPSC rejected the schedule: {reason}";
        }
    }

    /// λ = 0. Bonds only. Magnetization is the active invariant.
    operation IsingEvolution(register : Qubit[], steps : Int, dt : Double, j : Double) : Unit is Adj + Ctl {
        let schedule = Lemma_BondOrbit(Length(register));
        RequireAdmitted(Lemma_AllAdmitted(0, schedule), "ising ring");
        for _ in 1 .. steps {
            Lemma_Interpret(register, 0, schedule, j * dt);
        }
    }

    /// λ ≠ 0. Bond orbit plus transverse orbit. ∏ X is the active invariant.
    operation SpinFlipEvolution(
        register : Qubit[],
        steps : Int,
        dt : Double,
        j : Double,
        lam : Double
    ) : Unit is Adj + Ctl {
        let n = Length(register);
        let bonds = Lemma_BondOrbit(n);
        let field = Lemma_TransverseOrbit(n);
        RequireAdmitted(Lemma_AllAdmitted(1, bonds + field), "spin-flip orbit");
        for _ in 1 .. steps {
            Lemma_Interpret(register, 1, bonds, j * dt);
            Lemma_Interpret(register, 1, field, lam * dt);
        }
    }

    /// Refused schedule. Present so a host can see the lemma fail closed.
    operation RejectedIsingFlip(register : Qubit[], site : Int, angle : Double) : Unit is Adj + Ctl {
        let bad = [TransverseFlip(site)];
        RequireAdmitted(Lemma_AllAdmitted(0, bad), "single X breaks Ising magnetization");
        Lemma_Interpret(register, 0, bad, angle);
    }

    operation RejectedSpinFlipZ(register : Qubit[], site : Int, angle : Double) : Unit is Adj + Ctl {
        let bad = [LoneZ(site)];
        RequireAdmitted(Lemma_AllAdmitted(1, bad), "lone Z breaks prod X");
        Lemma_Interpret(register, 1, bad, angle);
    }

    /// Diagnostic, not a compiler filter.
    operation MeasureZParity(register : Qubit[]) : Int {
        mutable parity = 0;
        for q in register {
            if M(q) == One {
                set parity = (parity + 1) % 2;
            }
        }
        return parity;
    }

    /// Diagnostic for the spin-flip sector: measure every qubit in X and return the parity.
    operation MeasureXParity(register : Qubit[]) : Int {
        mutable parity = 0;
        for q in register {
            H(q);
            if M(q) == One {
                set parity = (parity + 1) % 2;
            }
        }
        return parity;
    }
}

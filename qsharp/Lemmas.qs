// *******************************************************************************
// Copyright (c) 2026 Ahmad Ali Parr and others.
//
// SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
// *******************************************************************************

namespace ConservationPreservingScattering {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;

    // Lemmas as total functions and interpreting operations.
    // Each one is the Q# image of a theorem in lean/CPSC/Lemmas.lean.

    function Lemma_NilAdmitted() : Bool {
        return true;
    }

    function Lemma_ConsAdmitted(mode : Int, head : GateKind, tailOk : Bool) : Bool {
        return Axiom_Preserves(mode, head) and tailOk;
    }

    function Lemma_AllAdmitted(mode : Int, schedule : GateKind[]) : Bool {
        mutable ok = true;
        for g in schedule {
            if not Axiom_Preserves(mode, g) {
                set ok = false;
            }
        }
        return ok;
    }

    function Lemma_AppendAdmitted(left : Bool, right : Bool) : Bool {
        return left and right;
    }

    function Lemma_TransverseBreaksIsing(q : Int) : Bool {
        return not Axiom_PreservesMagnetization(TransverseFlip(q));
    }

    function Lemma_LoneZBreaksSpinFlip(q : Int) : Bool {
        return not Axiom_PreservesSpinFlip(LoneZ(q));
    }

    operation Lemma_ApplyAdmitted(
        register : Qubit[],
        g : GateKind,
        angle : Double
    ) : Unit is Adj + Ctl {
        let n = Length(register);
        let q0 = g::Q0;
        let q1 = g::Q1;
        if q0 < 0 or q0 >= n or (q1 >= n) {
            fail "CPSC lemma: qubit outside the register";
        }
        if g::Tag == 0 {
            if q1 < 0 {
                fail "CPSC lemma: ZZ is missing its second qubit";
            }
            Axiom_ApplyZZ(register[q0], register[q1], angle);
        } elif g::Tag == 1 {
            if q1 < 0 {
                fail "CPSC lemma: pair is missing its second qubit";
            }
            Axiom_ApplyPair(register[q0], register[q1], angle);
        } elif g::Tag == 2 {
            Axiom_ApplyFlip(register[q0], angle);
        } elif g::Tag == 3 {
            Axiom_ApplyZ(register[q0], angle);
        } else {
            fail "CPSC lemma: unknown gate tag";
        }
    }

    // circuit_comm_*: interpret only an admitted schedule. A rejected head fails closed.
    operation Lemma_Interpret(
        register : Qubit[],
        mode : Int,
        schedule : GateKind[],
        angle : Double
    ) : Unit is Adj + Ctl {
        if not Lemma_AllAdmitted(mode, schedule) {
            fail "CPSC rejected the schedule: a factor breaks the active invariant";
        }
        for g in schedule {
            Lemma_ApplyAdmitted(register, g, angle);
        }
    }

    function Lemma_BondOrbit(n : Int) : GateKind[] {
        mutable gates = [];
        for i in 0 .. n - 1 {
            set gates += [ZZ(i, (i + 1) % n)];
        }
        return gates;
    }

    function Lemma_TransverseOrbit(n : Int) : GateKind[] {
        mutable gates = [];
        for i in 0 .. n - 1 {
            set gates += [TransverseFlip(i)];
        }
        return gates;
    }

    operation Lemma_IsingCircuit(register : Qubit[], angle : Double) : Unit is Adj + Ctl {
        let schedule = Lemma_BondOrbit(Length(register));
        Lemma_Interpret(register, 0, schedule, angle);
    }

    operation Lemma_SpinFlipCircuit(register : Qubit[], angle : Double) : Unit is Adj + Ctl {
        let n = Length(register);
        let schedule = Lemma_BondOrbit(n) + Lemma_TransverseOrbit(n);
        Lemma_Interpret(register, 1, schedule, angle);
    }
}

// *******************************************************************************
// Copyright (c) 2026 Ahmad Ali Parr and others.
//
// SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
// *******************************************************************************

namespace ConservationPreservingScattering {
    open Microsoft.Quantum.Intrinsic;

    // Operator axioms, as operations the compiler is allowed to emit.
    // Lean names are in comments. Q# has no proof kernel; admission is the Bool gate.

    newtype GateKind = (
        Tag : Int,
        Q0 : Int,
        Q1 : Int
    );

    function ZZ(q0 : Int, q1 : Int) : GateKind {
        return GateKind(0, q0, q1);
    }

    function ParityEvenPair(q0 : Int, q1 : Int) : GateKind {
        return GateKind(1, q0, q1);
    }

    function TransverseFlip(q : Int) : GateKind {
        return GateKind(2, q, -1);
    }

    function LoneZ(q : Int) : GateKind {
        return GateKind(3, q, -1);
    }

    // preservesMagnetization
    function Axiom_PreservesMagnetization(g : GateKind) : Bool {
        let tag = g::Tag;
        return tag == 0 or tag == 3;
    }

    // preservesSpinFlip
    function Axiom_PreservesSpinFlip(g : GateKind) : Bool {
        let tag = g::Tag;
        return tag == 0 or tag == 1 or tag == 2;
    }

    // Mode 0 is Ising, mode 1 is spin-flip. Mirrors `preserves`.
    function Axiom_Preserves(mode : Int, g : GateKind) : Bool {
        return mode == 0 ? Axiom_PreservesMagnetization(g) | Axiom_PreservesSpinFlip(g);
    }

    // zz_mag / zz_spin: a bond is legal in both modes.
    operation Axiom_ApplyZZ(left : Qubit, right : Qubit, angle : Double) : Unit is Adj + Ctl {
        Rzz(2.0 * angle, left, right);
    }

    // flip_spin: a transverse flip is legal only after the spin-flip axiom accepts it.
    operation Axiom_ApplyFlip(target : Qubit, angle : Double) : Unit is Adj + Ctl {
        Rx(2.0 * angle, target);
    }

    // z_mag: a lone Z is legal only in Ising mode.
    operation Axiom_ApplyZ(target : Qubit, angle : Double) : Unit is Adj + Ctl {
        Rz(2.0 * angle, target);
    }

    // pair_spin: two flips, the parity-even pair.
    operation Axiom_ApplyPair(left : Qubit, right : Qubit, angle : Double) : Unit is Adj + Ctl {
        Rx(2.0 * angle, left);
        Rx(2.0 * angle, right);
    }
}

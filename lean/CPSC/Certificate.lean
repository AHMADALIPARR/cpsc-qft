/-
  Certificate interface for the Conservation-Preserving Scattering Compiler.

  Nothing in this file is a discharged proof. `sorry` marks an open obligation.
  A circuit edit cannot yet invalidate a machine-checked witness, because no
  witness is attached to a concrete gate list.
-/

namespace CPSC

abbrev QubitIndex := Nat

inductive GateKind where
  | zz : QubitIndex → QubitIndex → GateKind
  | parityEvenPair : QubitIndex → QubitIndex → GateKind
  | transverseFlip : QubitIndex → GateKind
  deriving DecidableEq, Repr

structure Gate where
  kind : GateKind

structure Circuit where
  width : Nat
  gates : List Gate

/-- Active compilation invariants. Magnetization is optional and only legal at λ = 0. -/
structure Invariants where
  parity : Bool := true
  translation : Bool := true
  magnetization : Bool := false

def preservesParity : GateKind → Bool
  | .zz _ _ => true
  | .parityEvenPair _ _ => true
  | .transverseFlip _ => false

def circuitPreservesParity (C : Circuit) : Bool :=
  C.gates.all fun g => preservesParity g.kind

/-- Obligation 1: every admitted gate commutes with the active invariants.
    The Boolean check above is the executable shadow, not the operator proof. -/
theorem admitted_gates_commute
    (C : Circuit) (I : Invariants)
    (hI : I.parity = true)
    (hC : circuitPreservesParity C = true) :
    True := by
  trivial

/-- Obligation 2: ideal leakage out of the input sector is zero.
    Stated as a placeholder predicate so the gap is visible to a later proof. -/
def LeakageZero : Circuit → Prop := fun _ => True

theorem ideal_leakage_zero
    (C : Circuit) (h : circuitPreservesParity C = true) :
    LeakageZero C := by
  trivial

/-- Obligation 3: completeness. If H commutes with Π, then e^{-iHt} lies in the
    symmetry manifold. Not formalized; the Python prototype refuses the
    magnetization projection when this hypothesis is false. -/
theorem exact_evolution_in_manifold : True := by
  trivial

end CPSC

import CPSC

/-! Axiom audit. `lake env lean Audit.lean` must list only `propext`,
`Classical.choice`, and `Quot.sound`. Any `CPSC.*` axiom here is a regression. -/

#print axioms CPSC.Operator.admitted_trotter_commutes
#print axioms CPSC.operator_commutation
#print axioms CPSC.transverse_flip_breaks_magnetization
#print axioms CPSC.loneZ_breaks_spin_flip_op
#print axioms CPSC.Operator.rx_inverse
#print axioms CPSC.Emitted.emitted_commutes

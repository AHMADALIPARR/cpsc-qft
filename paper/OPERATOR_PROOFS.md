<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-->

# Appendix A: Operator proofs

Extracted from the paper PDF (Conservation-Preserving Compilation for a 1+1D Lattice Shadow of φ⁴). Every admitted Trotter schedule commutes with its mode's conserved operator. Each step is checked by the Lean theorem named in brackets. These sketches correspond to the development in `lean/CPSC/Operator.lean` (when present) and discharge the axioms previously stated in `Axioms.lean`.

## A.1 Setting

Fix \(N = n+1\) sites and a commutative ring \(R\). A basis string is a map \(b\) from sites to \(\{0,1\}\); a state is a map \(v\) from basis strings to \(R\), so \(R = \mathbb{C}\) gives \((\mathbb{C}^2)^{\otimes N}\). An operator is a map on states; product is composition. \(A\) commutes with \(P\) when \(A(Pv) = P(Av)\) for every \(v\) [`Commutes`]. Write \(\operatorname{sgn}(x) = (-1)^x\), \(b^{(q)}\) for \(b\) with bit \(q\) flipped [`flipAt`], and \(\bar{b}\) for \(b\) with every bit flipped [`flipAll`].

\[
(Z_q v)(b) = \operatorname{sgn}(b_q)\, v(b),\quad
(X_q v)(b) = v(b^{(q)}),\quad
(\Pi_X v)(b) = v(\bar{b}),\quad
(M v)(b) = m(b)\, v(b),\quad
m(b) = \sum_k \operatorname{sgn}(b_k).
\]

For \(\iota, c, s \in R\) the gates are the factors `cpsc.channel` applies:

\[
\begin{align*}
\mathrm{RZZ}_{pq}\, v(b) &= (c + \iota s\, \operatorname{sgn}(b_p)\operatorname{sgn}(b_q))\, v(b), \\
\mathrm{RX}_q\, v(b) &= c\, v(b) - \iota s\, v(b^{(q)}), \\
\mathrm{RZ}_q\, v(b) &= (c + \iota s\, \operatorname{sgn}(b_q))\, v(b), \\
\mathrm{PAIR}_{pq} &= \mathrm{RX}_p\, \mathrm{RX}_q.
\end{align*}
\]

## A.2 Gates are rotations

**Lemma A.1 (Pauli squares).** \(Z_q^2 = I\), \(X_q^2 = I\), \(\operatorname{sgn}(\neg x) = -\operatorname{sgn}(x)\), and \(\operatorname{sgn}(x)^2 = 1\). [`Z_sq`, `X_sq`, `sgn_not`, `sgn_sq`]  
*Proof.* \(\operatorname{sgn}\) takes values \(\pm 1\) and flipping a bit swaps them; flipping bit \(q\) twice returns \(b\).

**Proposition A.2 (Gate form).** \(\mathrm{RZZ}_{pq} = cI + \iota s\, Z_p Z_q\), \(\mathrm{RX}_q = cI - \iota s\, X_q\), and \(\mathrm{RZ}_q = cI + \iota s\, Z_q\). If \(\iota^2 = -1\) and \(c^2 + s^2 = 1\), the gate with \(s\) replaced by \(-s\) inverts \(\mathrm{RX}_q\). [`rzz_eq`, `rx_eq`, `rz_eq`, `rx_inverse`]  
*Proof.* Evaluate both sides at a basis string. For the inverse:
\[
(cI + \iota s\, X_q)(cI - \iota s\, X_q) = c^2 I - \iota^2 s^2 X_q^2 = (c^2 + s^2)I = I.
\]
Over \(\mathbb{C}\) with \(\iota = i\), \(c = \cos\theta\), \(s = \sin\theta\), \(P^2 = I\) gives \(\exp(\pm i\theta P) = \cos\theta\, I \pm i\sin\theta\, P\), so the gates are \(e^{i\theta Z_p Z_q}\), \(e^{-i\theta X_q}\), and \(e^{i\theta Z_q}\). (This identification is the one step not formalized; see Section 7 of the paper.)

## A.3 Commutation is closed under products

**Lemma A.3.** The identity commutes with every \(P\), and if \(A\) and \(B\) commute with \(P\), so does \(AB\). [`commutes_id`, `commutes_comp`]  
*Proof.* \(A(B(Pv)) = A(P(Bv)) = P(A(Bv))\).

## A.4 Admitted gates commute with the invariant

**Lemma A.4.** Flipping one bit commutes with flipping all bits. [`flipAt_flipAll`]

**Proposition A.5 (Spin flip).** \(\mathrm{RZZ}_{pq}\), \(\mathrm{RX}_q\), and \(\mathrm{PAIR}_{pq}\) commute with \(\Pi_X\) for all \(c, s, \iota\). [`rzz_comm_PiX`, `rx_comm_PiX`, `pair_comm_PiX`]  
*Proof.* For \(\mathrm{RZZ}\) both sides are a coefficient times \(v(\bar{b})\), and the coefficients agree because flipping all bits negates both signs, which cancel. For \(\mathrm{RX}\) both sides equal \(c\, v(\bar{b}) - \iota s\, v(\text{flipped }\bar{b})\), by Lemma A.4. \(\mathrm{PAIR}\) follows from Lemma A.3.

**Proposition A.6 (Magnetization).** \(\mathrm{RZZ}_{pq}\) and \(\mathrm{RZ}_q\) commute with \(M\) for all \(c, s, \iota\). [`diag_comm_Mag`, `rzz_comm_Mag`, `rz_comm_Mag`]  
*Proof.* All three are diagonal, and diagonal operators commute because \(R\) is commutative.

## A.5 Rejection is not vacuous

**Lemma A.7.** \(m(b^{(q)}) = m(b) - 2\operatorname{sgn}(b_q)\). [`magUpTo_flipAt`, `magVal_flipAt`]  
*Proof.* Only the \(q\)-th term of the sum changes; Lean proves it for every partial sum by induction.

**Proposition A.8.** If \(2\iota s \neq 0\) (over \(\mathbb{C}\): \(\sin\theta \neq 0\)), \(\mathrm{RX}_q\) does not commute with \(M\) and \(\mathrm{RZ}_q\) does not commute with \(\Pi_X\). [`rx_not_comm_Mag`, `rz_not_comm_PiX`]  
*Proof.* Take \(v \equiv 1\) and evaluate at the all-zero string. For \(\mathrm{RX}\), by Lemma A.7:
\[
(M\,\mathrm{RX}_q v)(0) - (\mathrm{RX}_q M v)(0) = m(0)(c - \iota s) - \bigl(c\, m(0) - \iota s\,(m(0) - 2)\bigr) = -2\iota s \neq 0.
\]
For \(\mathrm{RZ}\) the two sides are \(c + \iota s\) and \(c - \iota s\), which differ by \(2\iota s \neq 0\). The hypothesis is necessary: at \(\theta = 0\) or \(\pi\) the rotation is \(\pm I\).

## A.6 Main theorem

**Theorem A.9 (Admitted schedules conserve the invariant).** For either mode, with invariant \(M\) (Ising) or \(\Pi_X\) (spin-flip), and for every lattice size, commutative ring \(R\), \(\iota \in R\), angle map, admitted gate list, and number of Trotter steps \(k\), the Trotter operator \(\bigl(\prod_g \operatorname{gateOp}(g)\bigr)^k\) commutes with the invariant. [`admitted_trotter_commutes`]  
*Proof.* A gate passing `preservesMagnetization` is \(\mathrm{RZZ}\) or \(\mathrm{RZ}\) (Proposition A.6); a gate passing `preservesSpinFlip` is \(\mathrm{RZZ}\), \(\mathrm{RX}\), or \(\mathrm{PAIR}\) (Proposition A.5) [`mag_of_bool`, `spin_of_bool`]. Induction on the list with Lemma A.3 gives the layer [`circuit_comm`], and induction on \(k\) gives the power [`trotter_comm`].

**Corollary A.10 (Sector preservation).** If the invariant \(P\) satisfies \(P\psi_0 = \mu\psi_0\), then \(PU\psi_0 = UP\psi_0 = \mu U\psi_0\) for the emitted Trotter operator \(U\). The even cat state stays in the \(+1\) sector of \(\Pi_X\), and a basis state stays in its magnetization sector, at every step. This is the content of the zero-leakage rows in Section 6.

---

These sketches are the complete proof content of Appendix A. The corresponding Lean development (when `Operator.lean` is present) uses only Lean's standard axioms (`propext`, `Classical.choice`, `Quot.sound`).

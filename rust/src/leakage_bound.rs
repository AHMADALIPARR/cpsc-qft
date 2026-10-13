// Copyright (c) 2026 Ahmad Ali Parr and others.
// SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only

//! Numerical computation of the sector leakage bound
//! B = Σ_k γ_k ‖Π_leak L_k Π_comp‖_∞²

use nalgebra::{Complex, DMatrix, SVD};

#[derive(Debug, Clone)]
pub struct LindbladOperator {
    pub gamma: f64,
    pub matrix: DMatrix<Complex<f64>>,
}

#[derive(Debug)]
pub struct SectorProjectors {
    pub pi_comp: DMatrix<Complex<f64>>,
    pub pi_leak: DMatrix<Complex<f64>>,
}

impl SectorProjectors {
    pub fn new(dim: usize, comp_dim: usize) -> Self {
        let mut pi_comp = DMatrix::zeros(dim, dim);
        for i in 0..comp_dim {
            pi_comp[(i, i)] = Complex::new(1.0, 0.0);
        }
        let pi_leak = DMatrix::identity(dim, dim) - &pi_comp;
        Self { pi_comp, pi_leak }
    }
}

pub fn compute_leakage_bound(
    operators: &[LindbladOperator],
    projectors: &SectorProjectors,
) -> f64 {
    operators
        .iter()
        .map(|op| {
            let m_k = &projectors.pi_leak * &op.matrix * &projectors.pi_comp;
            let svd = SVD::new(m_k, true, true);
            let sigma_max = svd.singular_values.max().copied().unwrap_or(0.0);
            op.gamma * sigma_max * sigma_max
        })
        .sum()
}

fn main() {
    let dim = 4;
    let comp_dim = 2;
    let projectors = SectorProjectors::new(dim, comp_dim);

    let mut a_dag = DMatrix::zeros(dim, dim);
    for n in 0..dim - 1 {
        a_dag[(n, n + 1)] = Complex::new(((n + 1) as f64).sqrt(), 0.0);
    }

    let ops = vec![LindbladOperator {
        gamma: 1e-3,
        matrix: a_dag,
    }];

    let bound = compute_leakage_bound(&ops, &projectors);
    println!("Leakage bound B = {:.2e} (per unit time)", bound);
}

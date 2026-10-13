// Copyright (c) 2026 Ahmad Ali Parr and others.
// SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only

//! Truncated-oscillator encoding of a non-trivial φ⁴ interaction.
//! The quartic is constructed explicitly and certified non-identity / non-diagonal.

use nalgebra::{Complex, DMatrix};
use std::fs::File;
use std::io::Write;

pub struct Phi4Hamiltonian {
    pub dim: usize,
    pub lambda: f64,
    pub omega: f64,
    pub h_int: DMatrix<Complex<f64>>,
}

impl Phi4Hamiltonian {
    pub fn new(dim: usize, lambda: f64, omega: f64) -> Self {
        let mut a = DMatrix::zeros(dim, dim);
        let mut a_dag = DMatrix::zeros(dim, dim);
        for n in 0..dim - 1 {
            let val = Complex::new(((n + 1) as f64).sqrt(), 0.0);
            a[(n, n + 1)] = val;
            a_dag[(n + 1, n)] = val;
        }

        let phi = (&a + &a_dag) * Complex::new(1.0 / (2.0 * omega).sqrt(), 0.0);
        let phi2 = &phi * &phi;
        let phi4 = &phi2 * &phi2;
        let coeff = Complex::new(lambda / 24.0, 0.0);
        let h_int = phi4 * coeff;

        // Non-identity / non-diagonality certificate
        let diag_part = DMatrix::from_diagonal(&h_int.diagonal());
        let off_diag_norm = (&h_int - &diag_part).norm_frobenius();
        assert!(
            off_diag_norm > 1e-10,
            "φ⁴ appears diagonal (norm {}); truncation may be too small",
            off_diag_norm
        );

        if dim > 4 {
            assert!(
                phi4[(0, 2)].norm() > 1e-10,
                "Missing Δn = ±2 coupling"
            );
            assert!(
                phi4[(0, 4)].norm() > 1e-10,
                "Missing Δn = ±4 coupling"
            );
        }

        Self {
            dim,
            lambda,
            omega,
            h_int,
        }
    }

    pub fn export_matrix_market(&self, path: &str) -> std::io::Result<()> {
        let mut file = File::create(path)?;
        writeln!(file, "%%MatrixMarket matrix array complex general")?;
        writeln!(file, "{} {}", self.dim, self.dim)?;
        for j in 0..self.dim {
            for i in 0..self.dim {
                let v = self.h_int[(i, j)];
                writeln!(file, "{:.12e} {:.12e}", v.re, v.im)?;
            }
        }
        Ok(())
    }
}

fn main() {
    let h = Phi4Hamiltonian::new(8, 1.0, 1.0);
    println!(
        "φ⁴ matrix (dim={}) constructed. Frobenius norm: {:.4e}",
        h.dim,
        h.h_int.norm_frobenius()
    );
    h.export_matrix_market("phi4_hamiltonian.mtx")
        .expect("export failed");
    println!("Exported to phi4_hamiltonian.mtx");
}

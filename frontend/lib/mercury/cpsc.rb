# *******************************************************************************
# Copyright (c) 2026 Ahmad Ali Parr and others.
#
# This program and the accompanying materials are made available under the
# terms of the CPSC Eclipse Strict Copyleft License, Version 1.0, which is
# available in LICENSES/CPSC-ESCL-1.0.txt, or, at your option, under the
# GNU Affero General Public License, Version 3 only, which is available in
# LICENSES/AGPL-3.0.txt. Both options are strict copyleft. There is no
# classpath exception and no permissive relicensing.
#
# SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
# *******************************************************************************

# Ruby mirror of the CPSC Python analyzer (src/cpsc/analyzer.py) plus a
# Trotterized scattering evolution built as a Mercury circuit.
#
# Gate-kind semantics (identical to the Python original):
# - "magnetization": diagonal in the Z basis; preserves sum Z and prod Z.
# - "parity_even":   preserves prod Z (Z2 parity) but may change sum Z.
# - "illegal":      odd X/Y support; changes Z-parity. Rejected.
module Mercury
  module CPSC
    # Mercury gate -> analyzer kind. Mirrors analyzer.py's Gate kinds.
    KINDS = {
      i: "magnetization", z: "magnetization", s: "magnetization",
      t: "magnetization", sdg: "magnetization", tdg: "magnetization",
      rz: "magnetization", cz: "magnetization", rzz: "magnetization",
      cp: "magnetization",
      xx: "parity_even",
      x: "illegal", y: "illegal", h: "illegal",
      rx: "illegal", ry: "illegal", u: "illegal",
      cnot: "illegal", swap: "illegal", ccx: "illegal"
    }.freeze

    GateSpec = Struct.new(:name, :qubits, :kind)
    Rejection = Struct.new(:spec, :reason)

    class CompilationRejected < StandardError; end

    class SymmetryAnalyzer
      def initialize(n, conserve_magnetization: false)
        raise ArgumentError, "n must be positive" unless n.is_a?(Integer) && n >= 1
        @n = n
        @conserve_magnetization = conserve_magnetization
      end

      def check(specs)
        specs.flat_map do |spec|
          reason = reject_reason(spec)
          reason ? [Rejection.new(spec, reason)] : []
        end
      end

      def admit(specs)
        rejected = check(specs)
        unless rejected.empty?
          detail = rejected.map { |r| "#{r.spec.name}: #{r.reason}" }.join("; ")
          raise CompilationRejected, detail
        end
        specs.dup
      end

      private

      def reject_reason(spec)
        spec.qubits.each do |q|
          return "qubit #{q} outside lattice of size #{@n}" unless q.is_a?(Integer) && q.between?(0, @n - 1)
        end
        case spec.kind
        when "illegal"
          "odd X/Y support changes Z-parity; forbidden sector"
        when "parity_even", "magnetization"
          nil
        else
          "unknown gate kind #{spec.kind}"
        end
      end
    end

    # Classify a Mercury::Circuit::Op into a GateSpec for the analyzer.
    def self.classify(op)
      kind = KINDS.fetch(op.gate) { raise ArgumentError, "cannot classify #{op.gate}" }
      label = op.params.empty? ? op.gate.to_s.upcase : "#{op.gate}(#{op.params.map { |p| format('%.3f', p) }.join(',')})"
      GateSpec.new("#{label}[#{op.qubits.join(',')}]", op.qubits, kind)
    end

    # Run the analyzer over a whole circuit. Returns
    # { admitted: bool, rejections: [{gate, reason}] }.
    def self.analyze(circuit, conserve_magnetization: false)
      analyzer = SymmetryAnalyzer.new(circuit.n, conserve_magnetization: conserve_magnetization)
      specs = circuit.ops.reject { |op| op.gate == :measure }.map { |op| classify(op) }
      rejections = analyzer.check(specs)
      {
        admitted: rejections.empty?,
        rejections: rejections.map { |r| { gate: r.spec.name, reason: r.reason } }
      }
    end

    # First-order Trotter circuit for H = -J sum Z_i Z_{i+1} + lam sum X_i
    # (periodic), matching src/cpsc/hamiltonian.py. Per step dt:
    #   prod_bonds exp(+i J dt Z_i Z_{i+1}) then prod_i exp(-i lam dt X_i).
    def self.trotter_circuit(n, j:, lam:, time:, steps:)
      raise ArgumentError, "steps must be >= 1" unless steps >= 1
      dt = time.to_f / steps
      Circuit.new(n) do |c|
        steps.times do
          (0...n).each { |i| c.rzz(-2.0 * j * dt, i, (i + 1) % n) }
          (0...n).each { |i| c.rx(2.0 * lam * dt, i) } unless lam.zero?
        end
      end
    end

    def self.parity_of(basis, n)
      basis.to_s(2).count("1") & 1
    end

    def self.magnetization_of(basis, n)
      mag = 0
      n.times { |i| mag += ((basis >> i) & 1).zero? ? 1 : -1 }
      mag
    end

    # Probability mass outside the input Z2-parity sector.
    def self.leakage(amps, n, parity)
      wrong = 0.0
      amps.each_with_index do |a, b|
        wrong += a.abs**2 if parity_of(b, n) != parity
      end
      wrong
    end

    # <psi|H|psi> for the transverse-field Ising H, computed directly.
    def self.energy_expectation(amps, n, j:, lam:)
      dim = 1 << n
      e = 0.0
      dim.times do |s|
        p = amps[s].abs**2
        next if p.zero?
        zz = 0.0
        n.times do |i|
          zi = ((s >> i) & 1).zero? ? 1.0 : -1.0
          zj = ((s >> ((i + 1) % n)) & 1).zero? ? 1.0 : -1.0
          zz += zi * zj
        end
        e += p * (-j * zz)
      end
      unless lam.zero?
        x = 0.0
        n.times do |i|
          bit = 1 << i
          dim.times { |s| x += (amps[s].conj * amps[s ^ bit]).real }
        end
        e += lam * x
      end
      e
    end

  end
end

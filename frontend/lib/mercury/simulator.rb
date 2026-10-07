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

module Mercury
  # Full statevector simulator. Little-endian: qubit q is bit q of the
  # basis index, matching the Gates matrix convention.
  class Statevector
    attr_reader :n, :amps

    # initial: integer basis index, or MSB-first bitstring like "0011".
    def initialize(n, initial: 0)
      raise ArgumentError, "n must be >= 1" unless n.is_a?(Integer) && n >= 1
      initial = Integer(initial, 2) if initial.is_a?(String)
      raise ArgumentError, "initial basis out of range" unless initial.between?(0, (1 << n) - 1)
      @n = n
      @dim = 1 << n
      @amps = Array.new(@dim, Complex(0, 0))
      @amps[initial] = Complex(1, 0)
    end

    def dim
      @dim
    end

    def norm
      Math.sqrt(@amps.sum { |a| a.abs**2 })
    end

    def apply(gate, qubits, params = [])
      matrix = Gates.matrix(gate, params)
      case qubits.length
      when 1 then apply_one(matrix, qubits[0])
      when 2 then apply_two(matrix, qubits[0], qubits[1])
      when 3 then apply_three(matrix, qubits[0], qubits[1], qubits[2])
      else raise ArgumentError, "unsupported arity #{qubits.length}"
      end
      self
    end

    def probabilities
      @amps.map { |a| a.abs**2 }
    end

    # Sample `shots` bitstrings (MSB-first strings) from the distribution.
    def sample(shots, rng = Random.new)
      probs = probabilities
      cumulative = []
      total = 0.0
      probs.each { |p| total += p; cumulative << total }
      Array.new(shots) do
        r = rng.rand * total
        idx = cumulative.bsearch_index { |c| c >= r } || (@dim - 1)
        bitstring(idx)
      end
    end

    # Projective Z measurement of one qubit; collapses the state in place.
    def measure!(qubit, rng = Random.new)
      raise ArgumentError, "qubit out of range" unless qubit.between?(0, @n - 1)
      step = 1 << qubit
      p0 = 0.0
      @amps.each_with_index { |a, s| p0 += a.abs**2 if (s & step).zero? }
      outcome = rng.rand < p0 ? 0 : 1
      renorm = Math.sqrt(outcome.zero? ? p0 : (1.0 - p0))
      raise "measurement of zero-probability branch" if renorm.zero?
      @amps.each_with_index do |a, s|
        bit = (s & step).zero? ? 0 : 1
        @amps[s] = bit == outcome ? a / renorm : Complex(0, 0)
      end
      outcome
    end

    def bitstring(index)
      # MSB-first for display: qubit n-1 ... qubit 0
      (0...@n).map { |q| ((index >> (@n - 1 - q)) & 1).to_s }.join
    end

    private

    def apply_one(m, q)
      step = 1 << q
      nxt = Array.new(@dim, Complex(0, 0))
      (0...@dim).each do |s|
        next unless (s & step).zero?
        i0 = s
        i1 = s | step
        a0 = @amps[i0]
        a1 = @amps[i1]
        nxt[i0] = m[0][0] * a0 + m[0][1] * a1
        nxt[i1] = m[1][0] * a0 + m[1][1] * a1
      end
      @amps = nxt
    end

    def apply_two(m, q0, q1)
      raise ArgumentError, "q0 == q1" if q0 == q1
      s0 = 1 << q0
      s1 = 1 << q1
      nxt = Array.new(@dim, Complex(0, 0))
      (0...@dim).each do |s|
        next unless (s & s0).zero? && (s & s1).zero?
        idx = [s, s | s0, s | s1, s | s0 | s1]
        old = [(@amps[idx[0]]), (@amps[idx[1]]), (@amps[idx[2]]), (@amps[idx[3]])]
        4.times do |r|
          nxt[idx[r]] = m[r][0] * old[0] + m[r][1] * old[1] + m[r][2] * old[2] + m[r][3] * old[3]
        end
      end
      @amps = nxt
    end

    def apply_three(m, q0, q1, q2)
      raise ArgumentError, "repeated qubit" unless [q0, q1, q2].uniq.length == 3
      s0 = 1 << q0
      s1 = 1 << q1
      s2 = 1 << q2
      nxt = Array.new(@dim, Complex(0, 0))
      (0...@dim).each do |s|
        next unless (s & s0).zero? && (s & s1).zero? && (s & s2).zero?
        idx = (0...8).map { |b| s | ((b & 1) != 0 ? s0 : 0) | ((b & 2) != 0 ? s1 : 0) | ((b & 4) != 0 ? s2 : 0) }
        old = idx.map { |i| @amps[i] }
        8.times do |r|
          acc = Complex(0, 0)
          8.times { |cidx| acc += m[r][cidx] * old[cidx] }
          nxt[idx[r]] = acc
        end
      end
      @amps = nxt
    end
  end

  # Runs a Circuit. :measure ops collapse immediately; `shots` samples the
  # final distribution.
  class Simulator
    Result = Struct.new(:counts, :statevector, :probabilities, :measured)

    def run(circuit, shots: 0, seed: nil, initial: 0)
      rng = seed.nil? ? Random.new : Random.new(seed)
      sv = Statevector.new(circuit.n, initial: initial)
      measured = {}
      circuit.ops.each do |op|
        if op.gate == :measure
          measured[op.classical] = sv.measure!(op.qubits[0], rng)
        else
          sv.apply(op.gate, op.qubits, op.params)
        end
      end
      counts = {}
      if shots.positive?
        sv.sample(shots, rng).each { |b| counts[b] = (counts[b] || 0) + 1 }
      end
      Result.new(counts, sv.amps.dup, sv.probabilities, measured)
    end
  end
end

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

require "minitest/autorun"
require_relative "../lib/mercury"

def assert_unitary(name, params = [])
  m = Mercury::Gates.matrix(name, params)
  d = m.length
  d.times do |r|
    d.times do |c|
      acc = Complex(0, 0)
      d.times { |k| acc += m[r][k] * m[c][k].conj }
      expected = r == c ? Complex(1, 0) : Complex(0, 0)
      assert_in_delta expected.real, acc.real, 1e-12, "#{name} unitary [#{r},#{c}] real"
      assert_in_delta expected.imag, acc.imag, 1e-12, "#{name} unitary [#{r},#{c}] imag"
    end
  end
end

class TestGates < Minitest::Test
  def test_all_gates_unitary
    %i[i x y z h s t sdg tdg].each { |g| assert_unitary(g) }
    %i[rx ry rz].each { |g| [0.0, 0.7, Math::PI, -2.3].each { |t| assert_unitary(g, [t]) } }
    assert_unitary(:u, [0.7, 0.2, -0.5])
    %i[cnot cz swap xx].each { |g| assert_unitary(g) }
    assert_unitary(:cp, [1.1])
    assert_unitary(:rzz, [0.9])
    assert_unitary(:ccx)
  end

  def test_h_twice_is_identity
    c = Mercury::Circuit.new(1) { |cc| cc.h(0); cc.h(0) }
    res = Mercury::Simulator.new.run(c)
    assert_in_delta 1.0, res.probabilities[0], 1e-12
  end

  def test_x_flips
    c = Mercury::Circuit.new(1) { |cc| cc.x(0) }
    res = Mercury::Simulator.new.run(c)
    assert_in_delta 1.0, res.probabilities[1], 1e-12
  end

  def test_rx_pi_flips
    c = Mercury::Circuit.new(1) { |cc| cc.rx(Math::PI, 0) }
    res = Mercury::Simulator.new.run(c)
    assert_in_delta 1.0, res.probabilities[1], 1e-12
  end

  def test_cnot_truth_table
    # control=1, target=0 -> target flips; control as qubit 1, target qubit 0
    c = Mercury::Circuit.new(2) { |cc| cc.x(1); cc.cnot(1, 0) }
    res = Mercury::Simulator.new.run(c)
    assert_in_delta 1.0, res.probabilities[0b11], 1e-12
    # control=0 -> no flip
    c2 = Mercury::Circuit.new(2) { |cc| cc.x(0); cc.cnot(1, 0) }
    res2 = Mercury::Simulator.new.run(c2)
    assert_in_delta 1.0, res2.probabilities[0b01], 1e-12
  end

  def test_toffoli
    c = Mercury::Circuit.new(3) { |cc| cc.x(1); cc.x(2); cc.ccx(1, 2, 0) }
    res = Mercury::Simulator.new.run(c)
    assert_in_delta 1.0, res.probabilities[0b111], 1e-12
    c2 = Mercury::Circuit.new(3) { |cc| cc.x(1); cc.ccx(1, 2, 0) }
    res2 = Mercury::Simulator.new.run(c2)
    assert_in_delta 1.0, res2.probabilities[0b010], 1e-12
  end
end

class TestSimulator < Minitest::Test
  def test_bell_state
    c = Mercury::Circuit.new(2) { |cc| cc.h(0); cc.cnot(0, 1) }
    res = Mercury::Simulator.new.run(c)
    p = res.probabilities
    assert_in_delta 0.5, p[0b00], 1e-12
    assert_in_delta 0.5, p[0b11], 1e-12
    assert_in_delta 0.0, p[0b01], 1e-12
    assert_in_delta 0.0, p[0b10], 1e-12
  end

  def test_ghz3
    c = Mercury::Circuit.new(3) { |cc| cc.h(0); cc.cnot(0, 1); cc.cnot(1, 2) }
    res = Mercury::Simulator.new.run(c)
    p = res.probabilities
    assert_in_delta 0.5, p[0], 1e-12
    assert_in_delta 0.5, p[0b111], 1e-12
  end

  def test_qft_zero_is_uniform
    n = 3
    c = Mercury::Circuit.new(n)
    n.times do |j|
      c.h(j)
      ((j + 1)...n).each { |k| c.cp(Math::PI / (1 << (k - j)), k, j) }
    end
    (0...(n / 2)).each { |j| c.swap(j, n - 1 - j) }
    res = Mercury::Simulator.new.run(c)
    res.probabilities.each { |p| assert_in_delta 1.0 / 8, p, 1e-12 }
  end

  def test_measurement_collapses_then_samples
    # measure ops collapse first; sampling a collapsed state is deterministic
    c = Mercury::Circuit.new(2) { |cc| cc.h(0); cc.cnot(0, 1); cc.measure_all }
    res = Mercury::Simulator.new.run(c, shots: 2000, seed: 7)
    assert_equal 2000, res.counts.values.sum
    assert_equal 1, res.counts.keys.length, "collapsed state samples one outcome"
    assert_equal 1, res.measured.values.uniq.length, "Bell pair bits must agree"
  end

  def test_sampling_statistics_no_measure_ops
    c = Mercury::Circuit.new(2) { |cc| cc.h(0); cc.cnot(0, 1) }
    res = Mercury::Simulator.new.run(c, shots: 2000, seed: 7)
    assert_equal 2000, res.counts.values.sum
    assert res.counts.keys.all? { |b| %w[00 11].include?(b) }, "only 00/11, got #{res.counts.keys}"
    assert_in_delta 1000, res.counts["00"], 150
  end

  def test_norm_preserved_deep_circuit
    rng = Random.new(3)
    c = Mercury::Circuit.new(5)
    60.times do
      g = %i[h x y z s t rx ry rz].sample(random: rng)
      q = rng.rand(5)
      if %i[rx ry rz].include?(g)
        c.add(g, q, params: [rng.rand * 2 * Math::PI])
      else
        c.add(g, q)
      end
    end
    10.times do
      a, b = rng.rand(5), rng.rand(5)
      redo if a == b
      c.cnot(a, b)
    end
    res = Mercury::Simulator.new.run(c)
    assert_in_delta 1.0, res.probabilities.sum, 1e-9
  end

  def test_circuit_validation
    assert_raises(ArgumentError) { Mercury::Circuit.new(2) { |c| c.h(2) } }
    assert_raises(ArgumentError) { Mercury::Circuit.new(2) { |c| c.cnot(0, 0) } }
    assert_raises(ArgumentError) { Mercury::Circuit.new(2).add(:nope, 0) }
  end

  def test_initial_bitstring
    res = Mercury::Simulator.new.run(Mercury::Circuit.new(4), initial: "1010")
    assert_in_delta 1.0, res.probabilities[0b1010], 1e-12
  end
end

class TestCPSC < Minitest::Test
  def test_forbidden_bit_flip_rejected
    # mirrors tests/test_adversarial.py::test_forbidden_bit_flip_rejected_at_compile_time
    c = Mercury::Circuit.new(4) { |cc| cc.rzz(0.5, 0, 1); cc.x(2); cc.rzz(0.5, 2, 3) }
    verdict = Mercury::CPSC.analyze(c)
    refute verdict[:admitted]
    assert_equal 1, verdict[:rejections].length
    assert_match(/X/, verdict[:rejections][0][:gate])
    assert_match(/parity/i, verdict[:rejections][0][:reason])
  end

  def test_legal_circuit_admitted
    c = Mercury::Circuit.new(4) { |cc| cc.rzz(0.5, 0, 1); cc.rzz(0.5, 2, 3); cc.xx(1, 2) }
    verdict = Mercury::CPSC.analyze(c)
    assert verdict[:admitted], "expected admission, got #{verdict[:rejections]}"
  end

  def test_qubit_out_of_range_rejected
    analyzer = Mercury::CPSC::SymmetryAnalyzer.new(2)
    spec = Mercury::CPSC::GateSpec.new("Z[5]", [5], "magnetization")
    rej = analyzer.check([spec])
    assert_equal 1, rej.length
    assert_match(/outside lattice/, rej[0].reason)
  end

  def test_admit_raises_with_detail
    analyzer = Mercury::CPSC::SymmetryAnalyzer.new(4)
    bad = Mercury::CPSC::GateSpec.new("X[2]", [2], "illegal")
    err = assert_raises(Mercury::CPSC::CompilationRejected) { analyzer.admit([bad]) }
    assert_match(/X\[2\]/, err.message)
  end

  def test_trotter_lambda_zero_exact_sector
    n = 4
    init = 0b0011
    trotter = Mercury::CPSC.trotter_circuit(n, j: 1.0, lam: 0.0, time: 0.4, steps: 8)
    res = Mercury::Simulator.new.run(trotter, initial: init)
    parity = Mercury::CPSC.parity_of(init, n)
    assert_in_delta 0.0, Mercury::CPSC.leakage(res.statevector, n, parity), 1e-12
    assert_in_delta 1.0, res.probabilities.sum, 1e-12
    # magnetization conserved: only basis states with mag 0 carry weight
    res.statevector.each_with_index do |a, b|
      next if a.abs < 1e-12
      assert_equal 0, Mercury::CPSC.magnetization_of(b, n), "basis #{b.to_s(2)} leaked magnetically"
    end
  end

  def test_trotter_lambda_nonzero_honest_leakage
    n = 3
    init = 0b001
    trotter = Mercury::CPSC.trotter_circuit(n, j: 1.0, lam: 0.5, time: 0.3, steps: 12)
    res = Mercury::Simulator.new.run(trotter, initial: init)
    assert_in_delta 1.0, res.probabilities.sum, 1e-12
    leak = Mercury::CPSC.leakage(res.statevector, n, Mercury::CPSC.parity_of(init, n))
    assert leak > 0.0, "transverse field must mix parity sectors"
    assert leak < 0.5, "leakage #{leak} implausibly large for small evolution"
  end

  def test_energy_conserved_lambda_zero
    n = 4
    init = 0b0011
    e0 = Mercury::CPSC.energy_expectation(
      Mercury::Simulator.new.run(Mercury::Circuit.new(n), initial: init).statevector,
      n, j: 1.0, lam: 0.0
    )
    trotter = Mercury::CPSC.trotter_circuit(n, j: 1.0, lam: 0.0, time: 0.4, steps: 8)
    e1 = Mercury::CPSC.energy_expectation(
      Mercury::Simulator.new.run(trotter, initial: init).statevector,
      n, j: 1.0, lam: 0.0
    )
    assert_in_delta e0, e1, 1e-9
  end

  def test_xx_pair_preserves_parity_simulation
    c = Mercury::Circuit.new(3) { |cc| cc.xx(0, 2) }
    res = Mercury::Simulator.new.run(c, initial: 0b001)
    p0 = Mercury::CPSC.parity_of(0b001, 3)
    assert_in_delta 0.0, Mercury::CPSC.leakage(res.statevector, 3, p0), 1e-12
    assert_in_delta 1.0, res.probabilities[0b100], 1e-12
  end
end

class TestMiniJSON < Minitest::Test
  def test_round_trip
    obj = { "n" => 2, "ops" => [["h", [0], []], ["cnot", [0, 1], [0.5]]],
            "flag" => true, "nothing" => nil, "s" => "a\"b\\c" }
    assert_equal obj, Mercury::MiniJSON.parse(Mercury::MiniJSON.generate(obj))
  end

  def test_numbers
    assert_equal 42, Mercury::MiniJSON.parse("42")
    assert_in_delta 3.14, Mercury::MiniJSON.parse("3.14"), 1e-12
    assert_in_delta(-1.5e-3, Mercury::MiniJSON.parse("-1.5e-3"), 1e-15)
  end

  def test_bad_input_raises
    assert_raises(Mercury::MiniJSON::ParseError) { Mercury::MiniJSON.parse("{bad}") }
    assert_raises(Mercury::MiniJSON::ParseError) { Mercury::MiniJSON.parse("[1,2") }
  end
end

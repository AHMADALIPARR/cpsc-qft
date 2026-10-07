# ---- ../lib/mercury/version.rb ----
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
  VERSION = "0.1.0"
end

# ---- ../lib/mercury/gates.rb ----
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

# Gate matrices for Mercury. Little-endian convention: in a k-qubit gate
# applied to qubits [q0, q1, ...], matrix row/column index bit j (value
# 2**j) is the computational-basis state of qubit q_j. For a two-qubit
# gate on [q0, q1] the basis order is 00, 01, 10, 11 reading (bit1, bit0).
module Mercury
  module Gates
    ONE_QUBIT = %i[i x y z h s t sdg tdg rx ry rz u].freeze
    TWO_QUBIT = %i[cnot cz cp swap rzz xx].freeze
    THREE_QUBIT = %i[ccx].freeze

    PARAM_COUNTS = {
      i: 0, x: 0, y: 0, z: 0, h: 0, s: 0, t: 0, sdg: 0, tdg: 0,
      rx: 1, ry: 1, rz: 1, u: 3,
      cnot: 0, cz: 0, cp: 1, swap: 0, rzz: 1, xx: 0,
      ccx: 0
    }.freeze

    def self.arity(name)
      return 1 if ONE_QUBIT.include?(name)
      return 2 if TWO_QUBIT.include?(name)
      return 3 if THREE_QUBIT.include?(name)
      raise ArgumentError, "unknown gate #{name}"
    end

    def self.param_count(name)
      PARAM_COUNTS.fetch(name) { raise ArgumentError, "unknown gate #{name}" }
    end

    def self.matrix(name, params = [])
      need = param_count(name)
      raise ArgumentError, "#{name} needs #{need} params, got #{params.length}" unless params.length == need

      case name
      when :i then [[c(1), c(0)], [c(0), c(1)]]
      when :x then [[c(0), c(1)], [c(1), c(0)]]
      when :y then [[c(0), c(0, -1)], [c(0, 1), c(0)]]
      when :z then [[c(1), c(0)], [c(0), c(-1)]]
      when :h
        s = Math.sqrt(0.5)
        [[c(s), c(s)], [c(s), c(-s)]]
      when :s then [[c(1), c(0)], [c(0), c(0, 1)]]
      when :t then [[c(1), c(0)], [c(0), phase(Math::PI / 4)]]
      when :sdg then [[c(1), c(0)], [c(0), c(0, -1)]]
      when :tdg then [[c(1), c(0)], [c(0), phase(-Math::PI / 4)]]
      when :rx
        th = params[0] / 2.0
        co = c(Math.cos(th)); si = c(0, -Math.sin(th))
        [[co, si], [si, co]]
      when :ry
        th = params[0] / 2.0
        [[c(Math.cos(th)), c(-Math.sin(th))],
         [c(Math.sin(th)), c(Math.cos(th))]]
      when :rz
        th = params[0] / 2.0
        [[phase(-th), c(0)], [c(0), phase(th)]]
      when :u
        th, ph, la = params
        co = c(Math.cos(th / 2.0)); si = c(Math.sin(th / 2.0))
        [[co, c(-1) * phase(la) * si],
         [phase(ph) * si, phase(ph + la) * co]]
      when :cnot
        # qubits [target, control]; flips target iff control == 1
        [[c(1), c(0), c(0), c(0)],
         [c(0), c(1), c(0), c(0)],
         [c(0), c(0), c(0), c(1)],
         [c(0), c(0), c(1), c(0)]]
      when :cz
        [[c(1), c(0), c(0), c(0)],
         [c(0), c(1), c(0), c(0)],
         [c(0), c(0), c(1), c(0)],
         [c(0), c(0), c(0), c(-1)]]
      when :cp
        [[c(1), c(0), c(0), c(0)],
         [c(0), c(1), c(0), c(0)],
         [c(0), c(0), c(1), c(0)],
         [c(0), c(0), c(0), phase(params[0])]]
      when :swap
        [[c(1), c(0), c(0), c(0)],
         [c(0), c(0), c(1), c(0)],
         [c(0), c(1), c(0), c(0)],
         [c(0), c(0), c(0), c(1)]]
      when :rzz
        # exp(-i*theta/2 * ZxZ)
        a = phase(-params[0] / 2.0); b = phase(params[0] / 2.0)
        [[a, c(0), c(0), c(0)],
         [c(0), b, c(0), c(0)],
         [c(0), c(0), b, c(0)],
         [c(0), c(0), c(0), a]]
      when :xx
        # XxX: parity-even pair used by the CPSC analyzer
        [[c(0), c(0), c(0), c(1)],
         [c(0), c(0), c(1), c(0)],
         [c(0), c(1), c(0), c(0)],
         [c(1), c(0), c(0), c(0)]]
      when :ccx
        # qubits [target, control1, control2]; flips target iff both controls == 1
        m = Array.new(8) { |r| Array.new(8) { |col| c(r == col ? 1 : 0) } }
        m[6][6] = c(0); m[7][7] = c(0)
        m[6][7] = c(1); m[7][6] = c(1)
        m
      end
    end

    def self.c(re, im = 0)
      Complex(re, im)
    end

    def self.phase(angle)
      Complex(Math.cos(angle), Math.sin(angle))
    end
    private_class_method :c, :phase
  end
end

# ---- ../lib/mercury/circuit.rb ----
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
  # A quantum circuit: an ordered list of gate operations on n qubits.
  #
  #   c = Mercury::Circuit.new(2) do |c|
  #     c.h 0
  #     c.cnot 0, 1
  #     c.measure_all
  #   end
  #
  # Multi-qubit gate qubit order follows the Gates convention: for
  # cnot(control, target) the DSL takes (control, target) and stores
  # [target, control] so matrix bit 0 is the target. Same for ccx:
  # ccx(c1, c2, target) stores [target, c1, c2].
  class Circuit
    Op = Struct.new(:gate, :qubits, :params, :classical)

    attr_reader :n, :ops

    DSL_REORDER = { cnot: true, ccx: true }.freeze

    def initialize(n)
      raise ArgumentError, "n must be >= 1" unless n.is_a?(Integer) && n >= 1
      @n = n
      @ops = []
      yield self if block_given?
    end

    def add(gate, *qubits, params: [])
      gate = gate.to_sym
      arity = Gates.arity(gate)
      raise ArgumentError, "#{gate} takes #{arity} qubits, got #{qubits.length}" unless qubits.length == arity
      raise ArgumentError, "duplicate qubit in #{gate}#{qubits}" unless qubits.uniq.length == qubits.length
      qubits.each do |q|
        raise ArgumentError, "qubit #{q} out of range for #{@n} qubits" unless q.is_a?(Integer) && q >= 0 && q < @n
      end
      stored = DSL_REORDER[gate] ? qubits.reverse : qubits
      @ops << Op.new(gate, stored, params, nil)
      self
    end

    # Define h(0), x(1), rx(theta, 0), cnot(0, 1), ... from the gate registry.
    (Gates::ONE_QUBIT + Gates::TWO_QUBIT + Gates::THREE_QUBIT).each do |gname|
      define_method(gname) do |*args|
        need = Gates.param_count(gname)
        arity = Gates.arity(gname)
        raise ArgumentError, "#{gname} needs #{need} params + #{arity} qubits" if args.length < arity
        params = args.first(need)
        qubits = args.last(arity)
        add(gname, *qubits, params: params)
      end
    end

    def measure(qubit, clbit = nil)
      raise ArgumentError, "qubit #{qubit} out of range" unless qubit.is_a?(Integer) && qubit >= 0 && qubit < @n
      @ops << Op.new(:measure, [qubit], [], clbit || qubit)
      self
    end

    def measure_all
      @n.times { |q| measure(q, q) }
      self
    end

    def depth
      @ops.length
    end

    # Minimal Unicode circuit diagram.
    def to_s
      cols = @ops.map { |op| column(op) }
      rows = (0...@n).map do |q|
        label = "q#{q}: "
        body = cols.map { |col| col[q] }.join("")
        label + body
      end
      rows.join("\n")
    end

    private

    def column(op)
      cells = Array.new(@n, "────────")
      case op.gate
      when :measure
        cells[op.qubits[0]] = "───╫M───"
      else
        qs = op.qubits
        tag = op.params.empty? ? op.gate.to_s.upcase : "#{op.gate}#{op.params.map { |p| format('%.2f', p) }.join(',')}".upcase
        if qs.length == 1
          cells[qs[0]] = "───#{tag[0, 2]}───"
        else
          # multi-qubit: control dots on qs[1..], box on qs[0], rail between
          lo, hi = qs.minmax
          (lo..hi).each { |q| cells[q] = "───┼────" }
          cells[qs[0]] = "───#{tag[0, 2]}───"
          qs[1..].each { |q| cells[q] = "───●────" }
        end
      end
      cells
    end
  end
end

# ---- ../lib/mercury/simulator.rb ----
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

# ---- ../lib/mercury/mini_json.rb ----
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

# Minimal JSON parser/generator covering exactly what the Mercury web
# bridge needs (objects, arrays, strings, numbers, booleans, null).
# Pure Ruby, no dependencies — safe inside Ruby WASM.
module Mercury
  module MiniJSON
    class ParseError < StandardError; end

    def self.parse(str)
      @src = str
      @pos = 0
      skip_ws
      val = parse_value
      skip_ws
      raise ParseError, "trailing data at #{@pos}" unless @pos == @src.length
      val
    end

    def self.generate(obj)
      case obj
      when Hash
        "{" + obj.map { |k, v| "#{generate(k.to_s)}:#{generate(v)}" }.join(",") + "}"
      when Array
        "[" + obj.map { |v| generate(v) }.join(",") + "]"
      when String
        '"' + obj.gsub(/["\\\b\f\n\r\t]/) { |m| { '"' => '\\"', '\\' => '\\\\', "\b" => '\\b', "\f" => '\\f', "\n" => '\\n', "\r" => '\\r', "\t" => '\\t' }[m] } + '"'
      when Integer, Float
        raise ParseError, "non-finite number" if obj.is_a?(Float) && !obj.finite?
        obj.to_s
      when true then "true"
      when false then "false"
      when nil then "null"
      else
        raise ParseError, "cannot serialize #{obj.class}"
      end
    end

    def self.skip_ws
      @pos += 1 while @pos < @src.length && @src[@pos] =~ /\s/
    end

    def self.parse_value
      case @src[@pos]
      when '"' then parse_string
      when "{" then parse_object
      when "[" then parse_array
      when "t" then literal("true", true)
      when "f" then literal("false", false)
      when "n" then literal("null", nil)
      else parse_number
      end
    end

    def self.literal(word, val)
      raise ParseError, "bad literal at #{@pos}" unless @src[@pos, word.length] == word
      @pos += word.length
      val
    end

    def self.parse_string
      @pos += 1 # opening quote
      out = +""
      while @pos < @src.length
        ch = @src[@pos]
        case ch
        when '"'
          @pos += 1
          return out
        when "\\"
          @pos += 1
          esc = @src[@pos]
          out << case esc
                 when '"' then '"'
                 when "\\" then "\\"
                 when "/" then "/"
                 when "b" then "\b"
                 when "f" then "\f"
                 when "n" then "\n"
                 when "r" then "\r"
                 when "t" then "\t"
                 when "u"
                   hex = @src[@pos + 1, 4]
                   @pos += 4
                   [hex.to_i(16)].pack("U")
                 else raise ParseError, "bad escape at #{@pos}"
                 end
          @pos += 1
        else
          out << ch
          @pos += 1
        end
      end
      raise ParseError, "unterminated string"
    end

    def self.parse_object
      @pos += 1
      obj = {}
      skip_ws
      if @src[@pos] == "}"
        @pos += 1
        return obj
      end
      loop do
        skip_ws
        raise ParseError, "expected string key at #{@pos}" unless @src[@pos] == '"'
        key = parse_string
        skip_ws
        raise ParseError, "expected : at #{@pos}" unless @src[@pos] == ":"
        @pos += 1
        skip_ws
        obj[key] = parse_value
        skip_ws
        case @src[@pos]
        when "," then @pos += 1
        when "}" then @pos += 1; break
        else raise ParseError, "expected , or } at #{@pos}"
        end
      end
      obj
    end

    def self.parse_array
      @pos += 1
      arr = []
      skip_ws
      if @src[@pos] == "]"
        @pos += 1
        return arr
      end
      loop do
        skip_ws
        arr << parse_value
        skip_ws
        case @src[@pos]
        when "," then @pos += 1
        when "]" then @pos += 1; break
        else raise ParseError, "expected , or ] at #{@pos}"
        end
      end
      arr
    end

    def self.parse_number
      m = @src[@pos..].match(/\A-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/)
      raise ParseError, "bad number at #{@pos}" unless m
      @pos += m[0].length
      s = m[0]
      (s.include?(".") || s =~ /[eE]/) ? s.to_f : s.to_i
    end
  end
end

# ---- ../lib/mercury/cpsc.rb ----
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

# ---- app.rb ----
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

# Mercury web bridge. Concatenated after lib/mercury/*.rb by build.sh into
# mercury_bundle.rb, evaluated once inside Ruby WASM at boot. JavaScript
# drives it via vm.eval("handle_request('<json>')").
#
# Request:  {"n":2,"initial":"00","ops":[["h",[0],[]],["cnot",[0,1],[]]],
#            "shots":1024,"seed":42,"cpsc":true,"magnetization":false,
#            "j":1.0,"lam":0.0}
# Response: {"diagram":"...","probs":[[bits,p],...],"counts":{...},
#            "statevector":[[bits,re,im],...],"norm":1.0,
#            "cpsc":{"admitted":true,"rejections":[],"leakage":0.0,"energy":0.0}}

def bitstring_of(index, n)
  (0...n).map { |q| ((index >> (n - 1 - q)) & 1).to_s }.join
end

def handle_request(json_str)
  req = Mercury::MiniJSON.parse(json_str)
  n = req["n"].to_i
  raise "n must be 1..12" unless n.between?(1, 12)

  c = Mercury::Circuit.new(n)
  (req["ops"] || []).each do |op|
    name = op[0].to_s.to_sym
    qubits = op[1].map(&:to_i)
    params = (op[2] || []).map(&:to_f)
    c.add(name, *qubits, params: params)
  end

  initial = req.fetch("initial", "0" * n).to_s
  raise "initial must be #{n} bits" unless initial.match?(/\A[01]{#{n}}\z/)
  init_idx = Integer(initial, 2)

  shots = req.fetch("shots", 0).to_i
  seed = req["seed"]

  res = Mercury::Simulator.new.run(c, shots: shots, seed: seed, initial: init_idx)

  probs = []
  res.probabilities.each_with_index do |p, i|
    probs << [bitstring_of(i, n), p] if p > 1e-9
  end
  probs.sort_by! { |_, p| -p }

  sv = []
  res.statevector.each_with_index do |a, i|
    sv << [bitstring_of(i, n), a.real, a.imag] if a.abs > 1e-9
  end
  sv.sort_by! { |_, re, im| -(re * re + im * im) }

  out = {
    "diagram" => c.to_s,
    "probs" => probs.first(24),
    "counts" => res.counts,
    "statevector" => sv.first(24),
    "norm" => Math.sqrt(res.probabilities.sum)
  }

  if req["cpsc"]
    verdict = Mercury::CPSC.analyze(c, conserve_magnetization: !!req["magnetization"])
    out["cpsc"] = {
      "admitted" => verdict[:admitted],
      "rejections" => verdict[:rejections],
      "leakage" => Mercury::CPSC.leakage(res.statevector, n, Mercury::CPSC.parity_of(init_idx, n)),
      "energy" => Mercury::CPSC.energy_expectation(
        res.statevector, n,
        j: req.fetch("j", 1.0).to_f, lam: req.fetch("lam", 0.0).to_f
      )
    }
  end

  Mercury::MiniJSON.generate(out)
rescue => e
  Mercury::MiniJSON.generate({ "error" => "#{e.class}: #{e.message}" })
end


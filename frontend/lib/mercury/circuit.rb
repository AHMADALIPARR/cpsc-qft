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

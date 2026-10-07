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

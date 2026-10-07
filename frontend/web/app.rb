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

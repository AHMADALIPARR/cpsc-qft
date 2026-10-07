<!--
Copyright (c) 2026 Ahmad Ali Parr and others.
SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
-->

# Mercury — Ruby quantum circuit frontend for CPSC-QFT

A dependency-free Ruby quantum circuit library and full statevector
simulator, with a browser console (Ruby/WASM) for building circuits,
running them, and checking CPSC conservation laws at compile time.

## Layout

```
frontend/
  lib/mercury.rb              entry point (require this)
  lib/mercury/version.rb
  lib/mercury/gates.rb        gate matrices: H X Y Z S T Rx Ry Rz U,
                              CNOT CZ CP SWAP RZZ XX, Toffoli
  lib/mercury/circuit.rb      circuit DSL + Unicode diagram
  lib/mercury/simulator.rb    full statevector simulator
  lib/mercury/mini_json.rb    dependency-free JSON (WASM-safe)
  lib/mercury/cpsc.rb         CPSC bridge: symmetry analyzer, Trotter
                              scattering evolution, leakage, <H>
  test/test_mercury.rb        25 tests, 556 assertions (minitest, stdlib only)
  web/index.html              console template (= qsim.html after build)
  web/app.rb                  WASM bridge (handle_request)
  web/build.sh                builds mercury_bundle.rb + qsim.html
  web/qsim.html               the console (generated)
  web/mercury_bundle.rb       concatenated Ruby (generated, fetched at boot)
```

## Quickstart (Ruby)

```ruby
require_relative "lib/mercury"

# Bell pair
c = Mercury::Circuit.new(2) do |c|
  c.h 0
  c.cnot 0, 1
end
puts c.to_s

res = Mercury::Simulator.new.run(c, shots: 1000, seed: 42)
p res.counts  # {"00"=>..., "11"=>...}

# CPSC conservation check (mirrors src/cpsc/analyzer.py)
p Mercury::CPSC.analyze(c)
# => {:admitted=>false, :rejections=>[{:gate=>"H[0]", ...}, ...]}
# H and CNOT do not preserve the Z2 parity sector — rejected, as designed.

# Trotterized scattering: H = -J ΣZ_i Z_{i+1} + λ ΣX_i (periodic)
trotter = Mercury::CPSC.trotter_circuit(4, j: 1.0, lam: 0.0, time: 0.4, steps: 8)
psi = Mercury::Simulator.new.run(trotter, initial: "0011").statevector
p Mercury::CPSC.leakage(psi, 4, Mercury::CPSC.parity_of(0b0011, 4))  # => 0.0
```

Run the tests:

```bash
cd frontend && ruby -Ilib test/test_mercury.rb
```

## Web console

Build, then serve the `web/` directory over HTTP (WASM requires it):

```bash
cd frontend/web && ./build.sh
ruby -run -e httpd -- . -p 8123
# open http://localhost:8123/qsim.html
```

The console boots Ruby 3.2 (ruby.wasm, CDN) and evaluates the verbatim
`mercury_bundle.rb`. Features:

- circuit script editor (one op per line) + gate palette + presets
  (Bell, GHZ-3, QFT-3, Trotter scattering, adversarial X)
- Unicode circuit diagram, measurement histogram, statevector and
  probability tables
- CPSC panel: compile-time admission verdict, parity leakage,
  energy expectation — the analyzer rejects illegal gates before
  simulation, never post-selects after

To publish on GitHub Pages, copy `qsim.html` and `mercury_bundle.rb`
side-by-side into `docs/`.

## Notes

- Little-endian: qubit `q` is bit `q` of the basis index, matching the
  Python prototype's convention.
- At λ=0 the Trotter terms commute, so the Trotter circuit is exact:
  verified bit-identical against `cpsc.channel.evolve_in_sector`
  (max |Δ| = 0.0, n=4, t=0.4).
- At λ≠0 the transverse field genuinely mixes parity sectors; the
  console reports the honest leakage instead of projecting it away.
- `Mercury::CPSC.prepare` was removed in favor of `initial:` basis
  strings so state preparation never smuggles X gates past the analyzer.

## License

Dual strict copyleft: `LicenseRef-CPSC-ESCL-1.0` OR `AGPL-3.0-only`.
See the repository root `LICENSE`, `NOTICE`, `LICENSES/`.

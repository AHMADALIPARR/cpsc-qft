#!/bin/bash
# Build the Mercury web console:
#   mercury_bundle.rb — concatenated Ruby library + WASM bridge (fetched by qsim.html at boot)
#   qsim.html         — the console; references CDN wasm assets (works in any modern browser)
# Drop both files side-by-side anywhere static (e.g. docs/ for GitHub Pages).
set -euo pipefail
cd "$(dirname "$0")"

{
  for f in ../lib/mercury/version.rb \
           ../lib/mercury/gates.rb \
           ../lib/mercury/circuit.rb \
           ../lib/mercury/simulator.rb \
           ../lib/mercury/mini_json.rb \
           ../lib/mercury/cpsc.rb \
           app.rb; do
    echo "# ---- $f ----"
    cat "$f"
    echo ""
  done
} > mercury_bundle.rb

ruby -c mercury_bundle.rb
echo "wrote mercury_bundle.rb ($(wc -c < mercury_bundle.rb) bytes), qsim.html is index.html"
cp index.html qsim.html
echo "wrote qsim.html ($(wc -c < qsim.html) bytes)"

#!/usr/bin/env bash
set -euo pipefail
system="$(nix eval --impure --raw --expr 'builtins.currentSystem')"
mapfile -t names < <(
  nix eval --raw ".#packages.${system}" \
    --apply 'p: builtins.concatStringsSep "\n" (builtins.attrNames p)'
)
attrs=()
for name in "${names[@]}"; do
  [[ -n "$name" ]] || continue
  attrs+=(".#${name}")
done
nix build --accept-flake-config --show-trace -L "${attrs[@]}"

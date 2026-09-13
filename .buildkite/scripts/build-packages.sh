#!/usr/bin/env bash
# Build every installable in flake `packages` for the requested systems.
# Discovery is driven by `nix eval .#packages` so this script does not
# hardcode package names.
#
# Usage: build-packages.sh [filter]
#   omitted          currentSystem only
#   darwin           every *-darwin system exported by the flake
#   <system>         that exact flake system (e.g. aarch64-linux)
set -euo pipefail

filter="${1:-}"
current_host_system=""
if [[ -z "${filter}" ]]; then
  current_host_system="$(nix eval --impure --raw --expr 'builtins.currentSystem')"
fi

echo "--- :nix: discover flake packages"
discovered=$(nix eval --accept-flake-config --raw .#packages --apply '
  packages:
    let
      inherit (builtins) attrNames concatMap concatStringsSep sort;
      lt = a: b: a < b;
      systems = sort lt (attrNames packages);
      forSystem = system:
        map (name: "${system} ${name}")
          (sort lt (attrNames packages.${system}));
    in
    concatStringsSep "\n" (concatMap forSystem systems)
')

if [[ -z "${discovered}" ]]; then
  echo "+++ :x: flake packages discovery returned nothing"
  exit 1
fi

matches_filter() {
  local system="$1"
  case "${filter}" in
    "")
      [[ "${system}" == "${current_host_system}" ]]
      ;;
    darwin)
      [[ "${system}" == *-darwin ]]
      ;;
    *)
      [[ "${system}" == "${filter}" ]]
      ;;
  esac
}

selected=""
while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  system=${line%% *}
  if matches_filter "${system}"; then
    selected+="${line}"$'\n'
  fi
done <<< "${discovered}"

if [[ -z "${selected}" ]]; then
  echo "+++ :x: no packages matched filter '${filter:-currentSystem}'"
  echo "Discovered:"
  echo "${discovered}"
  exit 1
fi

echo "Filter: ${filter:-currentSystem}"
echo "${selected}"

section_emoji() {
  case "$1" in
    *-darwin) printf ':apple:' ;;
    *-linux) printf ':penguin:' ;;
    *) printf ':package:' ;;
  esac
}

current_system=""
installables=()

build_group() {
  if [[ -z "${current_system}" ]]; then
    return
  fi
  local emoji
  emoji=$(section_emoji "${current_system}")
  echo "--- ${emoji} ${current_system} packages ---"
  nix build --accept-flake-config --show-trace -L --max-jobs auto --cores 0 "${installables[@]}"
}

while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  system=${line%% *}
  name=${line#* }
  if [[ "${system}" != "${current_system}" ]]; then
    build_group
    current_system=${system}
    installables=()
  fi
  installables+=(".#packages.${system}.${name}")
done <<< "${selected}"

build_group

echo "+++ :white_check_mark: package builds succeeded"

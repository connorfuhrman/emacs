#!/usr/bin/env bash
# Build every installable in flake `packages` for the requested systems.
# Discovery is driven by `nix eval .#packages` so this script does not
# hardcode package names.
#
# Usage: build-packages.sh [filter...]
#   omitted          currentSystem only
#   darwin           every *-darwin system exported by the flake
#   <system>         that exact flake system (repeatable, e.g. aarch64-darwin aarch64-linux)
#
# Set NIX_BUILD_ALL=1 to realize every selected package in one nix build
# (better CPU saturation on hosted agents).
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=nix-ci-common.sh
source "${script_dir}/nix-ci-common.sh"

filters=("$@")
if [[ ${#filters[@]} -eq 0 ]]; then
  NIX_CI_CURRENT_SYSTEM="$(nix_ci_current_system)"
  export NIX_CI_CURRENT_SYSTEM
fi

echo "--- :nix: discover flake packages"
discovered=$(nix_ci_discover packages)

if [[ -z "${discovered}" ]]; then
  echo "+++ :x: flake packages discovery returned nothing"
  exit 1
fi

selected=$(nix_ci_select "${discovered}" "${filters[@]}")

if [[ -z "${selected}" ]]; then
  echo "+++ :x: no packages matched filter '${filters[*]:-currentSystem}'"
  echo "Discovered:"
  echo "${discovered}"
  exit 1
fi

echo "Filter: ${filters[*]:-currentSystem}"
echo "${selected}"

if [[ "${NIX_BUILD_ALL:-}" == "1" ]]; then
  installables=()
  first_system=""
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    system=${line%% *}
    name=${line#* }
    first_system=${first_system:-${system}}
    installables+=(".#packages.${system}.${name}")
  done <<< "${selected}"
  emoji=$(nix_ci_section_emoji "${first_system}")
  echo "--- ${emoji} packages (parallel) ---"
  nix_ci_build_all "${installables[@]}"
  echo "+++ :white_check_mark: package builds succeeded"
  exit 0
fi

current_system=""
installables=()

build_group() {
  if [[ -z "${current_system}" ]]; then
    return
  fi
  local emoji inst
  emoji=$(nix_ci_section_emoji "${current_system}")
  echo "--- ${emoji} ${current_system} packages ---"
  for inst in "${installables[@]}"; do
    nix_ci_build_one "${inst}"
  done
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

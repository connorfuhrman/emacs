#!/usr/bin/env bash
# Build every installable in flake `checks` for the requested systems.
# Discovery is driven by `nix eval .#checks` so this script does not
# hardcode check names.
#
# Usage: run-checks.sh [filter...]
#   omitted          currentSystem only
#   darwin           every *-darwin system exported by the flake
#   <system>         that exact flake system (repeatable)
#
# Set NIX_BUILD_ALL=1 to realize every selected check in one nix build.
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=nix-ci-common.sh
source "${script_dir}/nix-ci-common.sh"

filters=("$@")
if [[ ${#filters[@]} -eq 0 ]]; then
  NIX_CI_CURRENT_SYSTEM="$(nix_ci_current_system)"
  export NIX_CI_CURRENT_SYSTEM
fi

echo "--- :nix: discover flake checks"
discovered=$(nix_ci_discover checks)

if [[ -z "${discovered}" ]]; then
  echo "+++ :x: flake checks discovery returned nothing"
  exit 1
fi

selected=$(nix_ci_select "${discovered}" "${filters[@]}")

if [[ -z "${selected}" ]]; then
  echo "+++ :x: no checks matched filter '${filters[*]:-currentSystem}'"
  echo "Discovered:"
  echo "${discovered}"
  exit 1
fi

echo "Filter: ${filters[*]:-currentSystem}"
echo "${selected}"

installables=()
current_system=""

flush_group() {
  if [[ ${#installables[@]} -eq 0 ]]; then
    return
  fi
  local emoji inst
  emoji=$(nix_ci_section_emoji "${current_system}")
  echo "--- ${emoji} ${current_system} checks ---"
  if [[ "${NIX_BUILD_ALL:-}" == "1" ]]; then
    nix_ci_build_all "${installables[@]}"
  else
    for inst in "${installables[@]}"; do
      nix_ci_build_one "${inst}"
    done
  fi
}

while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  system=${line%% *}
  name=${line#* }
  if [[ "${system}" != "${current_system}" ]]; then
    flush_group
    current_system=${system}
    installables=()
  fi
  installables+=(".#checks.${system}.${name}")
done <<< "${selected}"

flush_group

echo "+++ :white_check_mark: flake checks succeeded"

#!/usr/bin/env bash
# Build every installable in flake `packages` for the requested systems.
# Discovery is driven by `nix eval .#packages` so this script does not
# hardcode package names. Container images (*-container) are excluded; use
# build-containers.sh for those.
#
# Usage: build-packages.sh [filter...]
#   omitted          currentSystem only
#   darwin           every *-darwin system exported by the flake
#   <system>         that exact flake system (repeatable, e.g. aarch64-darwin aarch64-linux)
set -euo pipefail

filters=("$@")
current_host_system=""
if [[ ${#filters[@]} -eq 0 ]]; then
  current_host_system="$(nix eval --impure --raw --expr 'builtins.currentSystem')"
fi

echo "--- :nix: discover flake packages"
discovered=$(nix eval --accept-flake-config --raw .#packages --apply '
  packages:
    let
      inherit (builtins) attrNames concatMap concatStringsSep sort;
      lt = a: b: a < b;
      isContainer = name: builtins.match ".*-container$" name != null;
      systems = sort lt (attrNames packages);
      forSystem = system:
        map (name: "${system} ${name}")
          (sort lt (builtins.filter (n: !isContainer n) (attrNames packages.${system})));
    in
    concatStringsSep "\n" (concatMap forSystem systems)
')

if [[ -z "${discovered}" ]]; then
  echo "+++ :x: flake packages discovery returned nothing"
  exit 1
fi

matches_filter() {
  local system="$1"
  if [[ ${#filters[@]} -eq 0 ]]; then
    [[ "${system}" == "${current_host_system}" ]]
    return
  fi
  local filter
  for filter in "${filters[@]}"; do
    case "${filter}" in
      darwin)
        [[ "${system}" == *-darwin ]] && return 0
        ;;
      *)
        [[ "${system}" == "${filter}" ]] && return 0
        ;;
    esac
  done
  return 1
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
  echo "+++ :x: no packages matched filter '${filters[*]:-currentSystem}'"
  echo "Discovered:"
  echo "${discovered}"
  exit 1
fi

echo "Filter: ${filters[*]:-currentSystem}"
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
  local inst err
  local -a nix_args=(
    --accept-flake-config
    --show-trace
    -L
    --max-jobs auto
    --cores 0
  )
  for inst in "${installables[@]}"; do
    echo "~~~ ${inst}"
    err=$(mktemp)
    if ! nix build "${nix_args[@]}" "${inst}" 2> >(tee "${err}" >&2); then
      echo "+++ :x: nix build failed: ${inst}"
      grep -oE '/nix/store/[0-9a-z]+-[^[:space:]'\''\"]+' "${err}" | sort -u | while read -r path; do
        echo "--- nix log ${path}"
        nix log "${path}" || true
      done
      rm -f "${err}"
      exit 1
    fi
    rm -f "${err}"
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

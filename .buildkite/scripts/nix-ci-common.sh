#!/usr/bin/env bash
# Shared helpers for discovering flake packages/checks and building them.
# Sourced by other .buildkite/scripts. Does not hardcode attr names.
# shellcheck shell=bash

# nixos/nix has no pager-friendly TTY; `nix log` otherwise hangs on less.
export PAGER="${PAGER:-cat}"
export NIX_PAGER="${NIX_PAGER:-cat}"
export GIT_PAGER="${GIT_PAGER:-cat}"

nix_ci_args=(
  --accept-flake-config
  --show-trace
  -L
  --keep-going
  --fallback
  --max-jobs auto
  --cores 0
  # Auto-GC mid-build deletes live inputs ("path is not valid") on
  # linux-builder and small hosted disks. Disable by keeping min-free at 0.
  --option min-free 0
)

# Darwin extra-platforms can substitute aarch64-linux into the macOS store,
# then `nix copy` those paths to linux-builder. After auto-GC they are
# invalid. Force remote-only realization so the VM substitutes from cache.
nix_ci_use_linux_builder() {
  local i
  for i in "${!nix_ci_args[@]}"; do
    if [[ "${nix_ci_args[$i]}" == "--max-jobs" ]]; then
      nix_ci_args[$((i + 1))]=0
    fi
  done
  nix_ci_args+=(--option builders-use-substitutes true)
  echo "linux-builder: max-jobs=0 builders-use-substitutes min-free=0"
}

nix_ci_maybe_use_linux_builder() {
  local filter
  if [[ "$(uname -s)" != Darwin ]]; then
    return
  fi
  for filter in "$@"; do
    if [[ "${filter}" == *-linux ]]; then
      nix_ci_use_linux_builder
      return
    fi
  done
}

nix_ci_current_system() {
  nix eval --impure --raw --expr 'builtins.currentSystem'
}

nix_ci_discover() {
  local kind="$1"
  nix eval --accept-flake-config --raw ".#${kind}" --apply '
    attrs:
      let
        inherit (builtins) attrNames concatMap concatStringsSep sort;
        lt = a: b: a < b;
        systems = sort lt (attrNames attrs);
        forSystem = system:
          map (name: "${system} ${name}")
            (sort lt (attrNames attrs.${system}));
      in
      concatStringsSep "\n" (concatMap forSystem systems)
  '
}

nix_ci_matches_filter() {
  local system="$1"
  shift
  local -a filters=("$@")
  local current_host_system="${NIX_CI_CURRENT_SYSTEM:-}"
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

nix_ci_select() {
  local discovered="$1"
  shift
  local -a filters=("$@")
  local selected="" line system
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    system=${line%% *}
    if nix_ci_matches_filter "${system}" "${filters[@]}"; then
      selected+="${line}"$'\n'
    fi
  done <<< "${discovered}"
  printf '%s' "${selected}"
}

nix_ci_section_emoji() {
  case "$1" in
    *-darwin) printf ':apple:' ;;
    *-linux) printf ':penguin:' ;;
    *) printf ':package:' ;;
  esac
}

nix_ci_dump_failed_logs() {
  local err_file="$1"
  local path count=0
  grep -oE '/nix/store/[0-9a-z]+-[^[:space:]'\''\"]+\.drv' "${err_file}" | sort -u | while read -r path; do
    count=$((count + 1))
    if ((count > 8)); then
      echo "--- skipping further nix log dumps"
      break
    fi
    echo "--- nix log ${path}"
    nix log --no-pager "${path}" 2>/dev/null || nix log "${path}" || true
  done
}

nix_ci_build_one() {
  local inst="$1"
  local err attempt=1
  local max_attempts="${NIX_CI_BUILD_ATTEMPTS:-3}"
  echo "~~~ ${inst}"
  err=$(mktemp)
  while ((attempt <= max_attempts)); do
    if nix build "${nix_ci_args[@]}" "${inst}" 2> >(tee "${err}" >&2); then
      rm -f "${err}"
      return 0
    fi
    echo "Attempt ${attempt}/${max_attempts} failed for ${inst}"
    nix_ci_dump_failed_logs "${err}"
    if ((attempt == max_attempts)); then
      echo "+++ :x: nix build failed: ${inst}"
      rm -f "${err}"
      return 1
    fi
    attempt=$((attempt + 1))
    sleep 15
  done
}

nix_ci_build_all() {
  local err
  echo "~~~ nix build (all installables, max-jobs=auto cores=0)"
  printf '    %s\n' "$@"
  err=$(mktemp)
  if ! nix build "${nix_ci_args[@]}" "$@" 2> >(tee "${err}" >&2); then
    echo "+++ :x: nix build failed"
    nix_ci_dump_failed_logs "${err}"
    rm -f "${err}"
    return 1
  fi
  rm -f "${err}"
}

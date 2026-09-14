#!/usr/bin/env bash
# Build OCI container images for a single flake system, smoke-test them, and
# stage tarballs for Buildkite artifact upload.
#
# Usage: build-containers.sh <system>
#   e.g. build-containers.sh x86_64-linux
set -euo pipefail

system="${1:?usage: build-containers.sh <system>}"

container_names=(
  emacs-nox-container
  emacs-unstable-nox-container
)

artifact_root="artifacts/containers/${system}"
mkdir -p "${artifact_root}"

load_cmd() {
  if command -v docker >/dev/null 2>&1; then
    printf 'docker'
  elif command -v podman >/dev/null 2>&1; then
    printf 'podman'
  else
    return 1
  fi
}

ensure_container_runtime() {
  if load_cmd >/dev/null 2>&1; then
    return 0
  fi
  if [[ -S /var/run/docker.sock ]] && command -v nix >/dev/null 2>&1; then
    docker_client="$(nix build --accept-flake-config --no-link --print-out-paths nixpkgs#docker.out 2>/dev/null || true)"
    if [[ -n "${docker_client}" ]]; then
      export PATH="${docker_client}/bin:${PATH}"
    fi
  fi
  load_cmd >/dev/null 2>&1
}

runtime=""
if ensure_container_runtime; then
  runtime="$(load_cmd)"
else
  echo "+++ :warning: no docker or podman found; skipping container load/run smoke tests"
fi

echo "--- :docker: build ${system} container images"
for name in "${container_names[@]}"; do
  installable=".#packages.${system}.${name}"
  echo "~~~ ${installable}"
  out_path="$(
    nix build \
      --accept-flake-config \
      --show-trace \
      -L \
      --max-jobs auto \
      --cores 0 \
      --print-out-paths \
      "${installable}"
  )"
  tarball="${artifact_root}/${name}.tar.gz"
  cp -fL "${out_path}" "${tarball}"
  echo "Staged ${tarball}"

  if [[ -n "${runtime}" ]]; then
    echo "--- :test_tube: smoke test ${name}"
    loaded="$("${runtime}" load -i "${tarball}")"
    image_ref=""
    while IFS= read -r line; do
      case "${line}" in
        "Loaded image: "*) image_ref="${line#Loaded image: }" ;;
      esac
    done <<< "${loaded}"
    if [[ -z "${image_ref}" ]]; then
      echo "+++ :x: could not parse image ref from ${runtime} load output"
      echo "${loaded}"
      exit 1
    fi
    "${runtime}" run --rm "${image_ref}" --version
    "${runtime}" run --rm "${image_ref}" -Q --batch --eval '(kill-emacs 0)'
    echo "Smoke test passed for ${image_ref}"
  fi
done

if command -v buildkite-agent >/dev/null 2>&1; then
  echo "--- :package: upload container artifacts"
  buildkite-agent artifact upload "${artifact_root}/**"
fi

echo "+++ :white_check_mark: container builds succeeded for ${system}"

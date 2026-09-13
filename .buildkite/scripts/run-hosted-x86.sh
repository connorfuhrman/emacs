#!/usr/bin/env bash
# Native x86_64-linux packages + flake checks on Buildkite hosted Linux.
# Samples host CPU while nix runs so we can confirm the queue is saturated
# (target: nominal CPU >80%). Uses max-jobs=auto and cores=0.
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=nix-ci-common.sh
source "${script_dir}/nix-ci-common.sh"

system="${HOSTED_NIX_SYSTEM:-x86_64-linux}"
host_system="$(nix_ci_current_system)"
nproc_out="$(nproc)"
echo "--- :chart_with_upwards_trend: hosted agent"
echo "builtins.currentSystem=${host_system}"
echo "nproc=${nproc_out}"
echo "queue=${BUILDKITE_AGENT_META_DATA_QUEUE:-unknown}"
echo "NIX_CONFIG=${NIX_CONFIG:-}"
if [[ "${host_system}" != "x86_64-linux" ]]; then
  echo "+++ :x: hosted job expected x86_64-linux, got ${host_system}"
  exit 1
fi

samples_file=$(mktemp)
stop_file=$(mktemp)
: >"${samples_file}"
echo "0" >"${stop_file}"

read_cpu_times() {
  # Aggregate all-CPU line from /proc/stat: user nice system idle iowait irq softirq steal
  awk '/^cpu / {
    idle=$5+$6
    total=0
    for (i=2; i<=NF; i++) total+=$i
    print idle, total
  }' /proc/stat
}

cpu_sampler() {
  local prev_idle prev_total idle total idle_d total_d pct
  read -r prev_idle prev_total < <(read_cpu_times)
  sleep 1
  while [[ "$(cat "${stop_file}")" == "0" ]]; do
    read -r idle total < <(read_cpu_times)
    idle_d=$((idle - prev_idle))
    total_d=$((total - prev_total))
    if ((total_d > 0)); then
      pct=$(awk -v idle="${idle_d}" -v total="${total_d}" 'BEGIN { printf "%.1f", (1 - idle/total) * 100 }')
      echo "${pct}" >>"${samples_file}"
    fi
    prev_idle=${idle}
    prev_total=${total}
    sleep 1
  done
}

cpu_sampler &
sampler_pid=$!
cleanup() {
  echo "1" >"${stop_file}"
  wait "${sampler_pid}" 2>/dev/null || true
  rm -f "${stop_file}"
}
trap cleanup EXIT

export NIX_BUILD_ALL=1

echo "--- :nix: ${system} packages + checks (parallel)"
pkg_disc=$(nix_ci_discover packages)
chk_disc=$(nix_ci_discover checks)
pkg_sel=$(nix_ci_select "${pkg_disc}" "${system}")
chk_sel=$(nix_ci_select "${chk_disc}" "${system}")

if [[ -z "${pkg_sel}" ]]; then
  echo "+++ :x: no packages for ${system}"
  echo "${pkg_disc}"
  exit 1
fi
if [[ -z "${chk_sel}" ]]; then
  echo "+++ :x: no checks for ${system}"
  echo "${chk_disc}"
  exit 1
fi

installables=()
while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  installables+=(".#packages.${line%% *}.${line#* }")
done <<< "${pkg_sel}"
while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  installables+=(".#checks.${line%% *}.${line#* }")
done <<< "${chk_sel}"

echo "Packages:"
echo "${pkg_sel}"
echo "Checks:"
echo "${chk_sel}"

set +e
nix_ci_build_all "${installables[@]}"
build_rc=$?
set -e

echo "1" >"${stop_file}"
wait "${sampler_pid}" 2>/dev/null || true
trap - EXIT
rm -f "${stop_file}"

sample_count=$(grep -c . "${samples_file}" || true)
if [[ "${sample_count}" -lt 1 ]]; then
  avg="0.0"
  peak="0.0"
else
  avg=$(awk '{s+=$1; n++} END { if (n) printf "%.1f", s/n; else print "0.0" }' "${samples_file}")
  peak=$(awk 'BEGIN{m=0} {if ($1+0>m) m=$1} END{printf "%.1f", m}' "${samples_file}")
fi
rm -f "${samples_file}"

if [[ "${build_rc}" -eq 0 ]]; then
  echo "+++ :white_check_mark: ${system} packages + checks succeeded"
else
  echo "+++ :x: ${system} packages + checks failed (exit ${build_rc})"
fi
echo "CPU samples=${sample_count} avg=${avg}% peak=${peak}% nproc=${nproc_out} queue=${BUILDKITE_AGENT_META_DATA_QUEUE:-unknown}"

report=$(
  cat <<EOF
### Hosted x86_64-linux CPU

| Field | Value |
|-------|-------|
| Queue | \`${BUILDKITE_AGENT_META_DATA_QUEUE:-unknown}\` |
| nproc | ${nproc_out} |
| currentSystem | \`${host_system}\` |
| Samples (1 Hz) | ${sample_count} |
| **Average CPU** | **${avg}%** |
| Peak CPU | ${peak}% |
| Nix | \`max-jobs = auto\`, \`cores = 0\` |
EOF
)

if command -v buildkite-agent >/dev/null 2>&1; then
  echo "${report}" | buildkite-agent annotate --style info --context hosted-x86-cpu
else
  echo "${report}"
fi

exit "${build_rc}"

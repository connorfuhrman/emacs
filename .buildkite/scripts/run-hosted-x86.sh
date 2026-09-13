#!/usr/bin/env bash
# Native x86_64-linux packages + flake checks on Buildkite hosted Linux.
# Samples /proc/stat in pure bash (nixos/nix has no awk) while nix runs so
# we can confirm the queue is saturated (target: nominal CPU >80%).
# Nix: max-jobs=auto, cores=0.
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=nix-ci-common.sh
source "${script_dir}/nix-ci-common.sh"

system="${HOSTED_NIX_SYSTEM:-x86_64-linux}"
host_system="$(nix_ci_current_system)"
nproc_out="$(nproc)"
queue_name="${BUILDKITE_AGENT_META_DATA_QUEUE:-unknown}"
echo "--- :chart_with_upwards_trend: hosted agent"
echo "builtins.currentSystem=${host_system}"
echo "nproc=${nproc_out}"
echo "queue=${queue_name}"
echo "NIX_CONFIG=${NIX_CONFIG:-}"
if [[ "${host_system}" != "x86_64-linux" ]]; then
  echo "+++ :x: hosted job expected x86_64-linux, got ${host_system}"
  exit 1
fi

samples_file=$(mktemp)
stop_file=$(mktemp)
: >"${samples_file}"
echo "0" >"${stop_file}"

# Integer tenths of a percent (853 => 85.3%). Avoids awk in nixos/nix.
fmt_pct() {
  local tenths="$1"
  printf '%d.%d' "$((tenths / 10))" "$((tenths % 10))"
}

read_cpu_times() {
  local _cpu user nice system idle iowait irq softirq steal _rest
  read -r _cpu user nice system idle iowait irq softirq steal _rest </proc/stat
  local idle_all=$((idle + iowait))
  local total=$((user + nice + system + idle + iowait + irq + softirq + steal))
  printf '%s %s\n' "${idle_all}" "${total}"
}

summarize_samples() {
  local sum=0 n=0 peak=0 v
  while read -r v; do
    [[ -z "${v}" ]] && continue
    sum=$((sum + v))
    n=$((n + 1))
    if ((v > peak)); then
      peak=${v}
    fi
  done <"${samples_file}"
  if ((n < 1)); then
    echo "0 0.0 0.0"
    return
  fi
  local avg_t=$((sum / n))
  echo "${n} $(fmt_pct "${avg_t}") $(fmt_pct "${peak}")"
}

write_cpu_report() {
  local sample_count="$1" avg="$2" peak="$3" note="${4:-}"
  cat <<EOF
### Hosted x86_64-linux CPU

| Field | Value |
|-------|-------|
| Queue | \`${queue_name}\` |
| nproc | ${nproc_out} |
| currentSystem | \`${host_system}\` |
| Samples (1 Hz) | ${sample_count} |
| **Average CPU** | **${avg}%** |
| Peak CPU | ${peak}% |
| Nix | \`max-jobs = auto\`, \`cores = 0\` |
${note}
EOF
}

annotate_cpu() {
  local sample_count="$1" avg="$2" peak="$3" note="${4:-}"
  local report
  report=$(write_cpu_report "${sample_count}" "${avg}" "${peak}" "${note}")
  echo "${report}"
  if command -v buildkite-agent >/dev/null 2>&1; then
    echo "${report}" | buildkite-agent annotate --style info --context hosted-x86-cpu || true
  fi
}

cpu_sampler() {
  local prev_idle prev_total idle total idle_d total_d tenths ticks=0
  read -r prev_idle prev_total < <(read_cpu_times)
  sleep 1
  while [[ "$(cat "${stop_file}")" == "0" ]]; do
    read -r idle total < <(read_cpu_times)
    idle_d=$((idle - prev_idle))
    total_d=$((total - prev_total))
    if ((total_d > 0)); then
      tenths=$(((total_d - idle_d) * 1000 / total_d))
      echo "${tenths}" >>"${samples_file}"
      ticks=$((ticks + 1))
      if ((ticks > 0 && ticks % 60 == 0)); then
        set -- $(summarize_samples)
        echo "~~~ CPU after ${ticks}s: samples=$1 avg=$2% peak=$3% nproc=${nproc_out} queue=${queue_name}"
        annotate_cpu "$1" "$2" "$3" "Interim sample after ${ticks} seconds of nix work."
      fi
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
build_rc=1
attempt=1
while ((attempt <= 3)); do
  echo "--- :nix: build attempt ${attempt}/3"
  nix_ci_build_all "${installables[@]}"
  build_rc=$?
  if [[ "${build_rc}" -eq 0 ]]; then
    break
  fi
  echo "^^^ +++"
  echo "Attempt ${attempt} failed (exit ${build_rc}); retrying transient fetch/build errors"
  attempt=$((attempt + 1))
  sleep 15
done
set -e

echo "1" >"${stop_file}"
wait "${sampler_pid}" 2>/dev/null || true
trap - EXIT
rm -f "${stop_file}"

set -- $(summarize_samples)
sample_count=$1
avg=$2
peak=$3
rm -f "${samples_file}"

if [[ "${build_rc}" -eq 0 ]]; then
  echo "+++ :white_check_mark: ${system} packages + checks succeeded"
else
  echo "+++ :x: ${system} packages + checks failed (exit ${build_rc})"
fi
echo "CPU samples=${sample_count} avg=${avg}% peak=${peak}% nproc=${nproc_out} queue=${queue_name}"

annotate_cpu "${sample_count}" "${avg}" "${peak}" "Final average over the full nix packages+checks job."

exit "${build_rc}"

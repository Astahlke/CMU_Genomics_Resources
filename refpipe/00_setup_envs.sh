#!/usr/bin/env bash
# Checks the conda environments and tools this pipeline needs, and installs anything missing.
# Run on a compile node (acompile), not a login node:   bash 00_setup_envs.sh
# Safe to rerun. It never deletes or rebuilds an environment that already exists.
set -uo pipefail
source "${CONFIG:-config.sh}"

if [[ "$(hostname)" == login* ]] && [ -z "${ALLOW_LOGIN:-}" ]; then
  echo "This looks like a login node. Run 'acompile' first (or set ALLOW_LOGIN=1 to override)." >&2; exit 1
fi
if ! command -v conda >/dev/null 2>&1 && command -v module >/dev/null 2>&1; then
  module load miniforge || true
fi
command -v conda >/dev/null 2>&1 || { echo "conda not found. On CURC: module load miniforge" >&2; exit 1; }
eval "$(conda shell.bash hook)"

CH="--strict-channel-priority -c conda-forge -c bioconda"
missing_tools() {   # $1 env, $2 tools -> prints the tools not found in that env
  local env=$1 t out=""
  for t in $2; do conda run -n "$env" bash -c "command -v $t" >/dev/null 2>&1 || out="$out $t"; done
  echo "$out"
}
ensure_env() {      # $1 env name, $2 packages, $3 tools that must be present
  local env=$1 pkgs=$2 tools=$3 miss
  if conda env list | awk '{print $1}' | grep -qx "$env"; then
    echo "[ok]      environment '$env' exists"
  else
    echo "[install] creating environment '$env' ($pkgs) ..."
    conda create -y -n "$env" $CH $pkgs || { echo "[FAIL] could not create '$env'" >&2; return 1; }
  fi
  miss=$(missing_tools "$env" "$tools")
  if [ -n "$miss" ]; then
    echo "[install] '$env' is missing:$miss; installing packages ..."
    conda install -y -n "$env" $CH $pkgs || { echo "[FAIL] install into '$env' failed" >&2; return 1; }
    miss=$(missing_tools "$env" "$tools")
  fi
  if [ -n "$miss" ]; then echo "[FAIL] '$env' still missing:$miss" >&2; return 1; fi
  echo "[ok]      '$env' has: $tools"
}

rc=0
ensure_env "$ENV_REFBUILD" "entrez-direct seqkit vsearch mafft python=3.11" "esearch efetch xtract seqkit vsearch mafft python3" || rc=1
ensure_env "$ENV_KRAKEN2"  "kraken2 bracken seqkit python=3.11" "kraken2 kraken2-build bracken bracken-build seqkit python3" || rc=1

[ -n "${NCBI_API_KEY:-}" ] && echo "[ok]      NCBI_API_KEY is set (value not shown)" \
                           || echo "[note]    NCBI_API_KEY is not set; NCBI will allow only 3 requests per second"
if [ "$rc" -eq 0 ]; then echo "All set."; else echo "Some installs failed; see messages above." >&2; fi
exit $rc

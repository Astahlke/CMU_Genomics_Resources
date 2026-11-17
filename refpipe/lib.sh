# Sourced by the step scripts. require TOOL... stops with a clear message if a tool is not on the PATH.
require() {
  local missing=0 t
  for t in "$@"; do
    command -v "$t" >/dev/null 2>&1 || { echo "MISSING TOOL: $t" >&2; missing=1; }
  done
  if [ "$missing" -ne 0 ]; then
    echo "Fix: run 'bash 00_setup_envs.sh', then 'conda activate <env>' (refbuild for steps 01-03, kraken2 for 04-07)." >&2
    exit 1
  fi
}

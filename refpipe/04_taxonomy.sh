#!/usr/bin/env bash
# Environment: kraken2. Puts a taxonomy/ folder in OUTDIR/kraken_db
set -euo pipefail
source "${CONFIG:-config.sh}"
source "$(dirname "$0")/lib.sh"
require kraken2-build
DB="$OUTDIR/kraken_db"; mkdir -p "$DB"
if [ -s "$DB/taxonomy/nodes.dmp" ]; then echo "Taxonomy already present"; exit 0; fi
if [ -n "${TAXONOMY_FROM:-}" ]; then
  cp -r "$TAXONOMY_FROM" "$DB/taxonomy"
else
  # rsync is blocked from CURC compute nodes; use FTP and skip the huge accession maps (our headers carry taxids).
  # Check these options with: kraken2-build --help
  kraken2-build --download-taxonomy --skip-maps --use-ftp --db "$DB"
fi
[ -s "$DB/taxonomy/nodes.dmp" ] && [ -s "$DB/taxonomy/names.dmp" ] || { echo "taxonomy missing nodes.dmp or names.dmp" >&2; exit 1; }
echo "Taxonomy ready: $DB/taxonomy"

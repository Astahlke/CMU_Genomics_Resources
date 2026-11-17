#!/usr/bin/env bash
# Environment: any with python3. Writes OUTDIR/<MARKER>_clean.fasta (valid TaxIDs only)
set -euo pipefail
source "${CONFIG:-config.sh}"
source "$(dirname "$0")/lib.sh"
require python3
python3 -I "$(dirname "$0")/fix_taxids.py" "$OUTDIR/kraken_db/taxonomy" \
  "$OUTDIR/${MARKER}_by_taxid.fasta" "$OUTDIR/${MARKER}_clean.fasta" "$OUTDIR/taxid_fixes.tsv"
echo "Sequences in clean FASTA: $(grep -c '^>' "$OUTDIR/${MARKER}_clean.fasta")"

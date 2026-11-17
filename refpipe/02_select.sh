#!/usr/bin/env bash
# Environment: any. Keeps up to MAX_PER_TAXID records per TaxID (longest first). Writes OUTDIR/selected.tsv
set -euo pipefail
source "${CONFIG:-config.sh}"
R="$OUTDIR/records.tsv"
tail -n +2 "$R" | awk -F'\t' '$2!="NA" && $2!="" && !acc[$1]++' \
  | sort -t$'\t' -k2,2n -k4,4nr \
  | awk -F'\t' -v m="$MAX_PER_TAXID" 'seen[$2]++ < m' > "$OUTDIR/selected.tsv"
echo "Records: $(($(wc -l < "$R") - 1))"
echo "TaxIDs:  $(cut -f2 "$OUTDIR/selected.tsv" | sort -u | wc -l)"
echo "Selected sequences: $(wc -l < "$OUTDIR/selected.tsv")"

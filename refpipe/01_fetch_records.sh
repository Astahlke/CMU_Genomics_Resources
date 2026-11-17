#!/usr/bin/env bash
# Environment: refbuild (entrez-direct). Writes OUTDIR/records.tsv
set -euo pipefail
source "${CONFIG:-config.sh}"
source "$(dirname "$0")/lib.sh"
require esearch efetch xtract
mkdir -p "$OUTDIR"
Q="$QUERY AND $ORG AND ${MINLEN}:${MAXLEN}[SLEN]"      # rebuilt on every run: never reuse an old $Q
[ -n "${EXTRA:-}" ] && Q="$Q AND $EXTRA"
echo "Query: $Q"
count=$(esearch -db nuccore -query "$Q" | xtract -pattern ENTREZ_DIRECT -element Count)
echo "Records matching: $count"
if [ "${count:-0}" -lt 1 ]; then echo "No records found. Check QUERY, ORG and the length window." >&2; exit 1; fi
printf 'accession\ttaxid\tspecies\tlength\ttitle\n' > "$OUTDIR/records.tsv"
esearch -db nuccore -query "$Q" | efetch -format docsum \
  | xtract -pattern DocumentSummary -def "NA" -element AccessionVersion TaxId Organism Slen Title >> "$OUTDIR/records.tsv"
echo "Wrote $(($(wc -l < "$OUTDIR/records.tsv") - 1)) records to $OUTDIR/records.tsv"
echo "Length distribution (length, count):"
tail -n +2 "$OUTDIR/records.tsv" | cut -f4 | sort -n | uniq -c | awk '{print $2"\t"$1}' | head -40

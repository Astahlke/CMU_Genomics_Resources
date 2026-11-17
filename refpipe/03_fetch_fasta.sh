#!/usr/bin/env bash
# Environment: refbuild (entrez-direct). One FASTA with headers >ACC|kraken:taxid|TAXID description
# Safe to rerun: accessions already in the output are skipped. No batches folder; temp files are removed on exit.
set -euo pipefail
source "${CONFIG:-config.sh}"
source "$(dirname "$0")/lib.sh"
require esearch efetch xtract
SEL="$OUTDIR/selected.tsv"
OUT="$OUTDIR/${MARKER}_by_taxid.fasta"
FAILED="$OUTDIR/failed_accessions.txt"
touch "$OUT"; : > "$FAILED"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
cut -f1,2 "$SEL" > "$TMP/map.tsv"
{ grep '^>' "$OUT" || true; } | cut -d'|' -f1 | tr -d '>' | sort -u > "$TMP/have.txt"
cut -f1 "$SEL" | sort -u | comm -23 - "$TMP/have.txt" > "$TMP/need.txt"
echo "Need $(wc -l < "$TMP/need.txt") accessions ($(wc -l < "$TMP/have.txt") already downloaded)"

rewrite() {   # stdin FASTA from efetch -> stdout with kraken headers (drops anything not in the map)
  awk 'BEGIN{FS="\t"} NR==FNR{t[$1]=$2; next}
       /^>/ {split(substr($0,2),a," "); acc=a[1]; rest=substr($0,length(acc)+2);
             if (acc in t) {keep=1; print ">" acc "|kraken:taxid|" t[acc] rest} else keep=0; next}
       keep {print}' "$TMP/map.tsv" -
}
fetch_ids() { # $1 = comma-separated accessions; appends to OUT; returns 1 on failure
  local try
  for try in 1 2 3; do
    if efetch -db nuccore -id "$1" -format fasta > "$TMP/raw.fa" 2> "$TMP/err.txt" && [ -s "$TMP/raw.fa" ]; then
      rewrite < "$TMP/raw.fa" >> "$OUT"; return 0
    fi
    sleep $((try * 3))
  done
  return 1
}
split -l "$BATCH" "$TMP/need.txt" "$TMP/chunk_"
for c in "$TMP"/chunk_*; do
  [ -e "$c" ] || continue
  if fetch_ids "$(paste -sd, "$c")"; then
    echo "fetched batch of $(wc -l < "$c")"
  else
    echo "batch failed; trying one accession at a time"
    while read -r acc; do
      fetch_ids "$acc" || echo "$acc" >> "$FAILED"
      sleep 0.4
    done < "$c"
  fi
  sleep 0.4
done
echo "FASTA records: $(grep -c '^>' "$OUT") of $(wc -l < "$SEL") selected"
echo "Failed accessions: $(wc -l < "$FAILED") (see $FAILED)"

#!/usr/bin/env bash
# Environment: any. Builds the folder students point EPI2ME at (Kraken2 mode) and the minimap2 reference set.
set -euo pipefail
source "${CONFIG:-config.sh}"
DB="$OUTDIR/kraken_db"; FA="$OUTDIR/${MARKER}_clean.fasta"

# --- Kraken2 mode: database + taxonomy + Bracken files
K="$OUTDIR/epi2me_kraken2_${MARKER}"; rm -rf "$K"; mkdir -p "$K/taxdump"
cp "$DB"/hash.k2d "$DB"/opts.k2d "$DB"/taxo.k2d "$K/"
cp "$DB"/database*mers.kmer_distrib "$K/"
cp "$DB/taxonomy/nodes.dmp" "$DB/taxonomy/names.dmp" "$K/taxdump/"

# --- minimap2 mode: reference FASTA + ref2taxid (no header) + taxonomy
M="$OUTDIR/epi2me_minimap2_${MARKER}"; rm -rf "$M"; mkdir -p "$M/taxdump"
awk '/^>/ {split(substr($0,2),a,"|"); print ">" a[1]; next} {print}' "$FA" > "$M/${MARKER}_minimap2.fasta"
awk -F'|' '/^>/ {split($3,b," "); sub(/^>/,"",$1); print $1 "\t" b[1]}' "$FA" > "$M/${MARKER}.ref2taxid.tsv"
cp "$DB/taxonomy/nodes.dmp" "$DB/taxonomy/names.dmp" "$M/taxdump/"

# --- checks
nf=$(grep -c '^>' "$M/${MARKER}_minimap2.fasta"); nm=$(wc -l < "$M/${MARKER}.ref2taxid.tsv")
echo "minimap2 FASTA records: $nf   ref2taxid rows: $nm"
dups=$(cut -f1 "$M/${MARKER}.ref2taxid.tsv" | sort | uniq -d | wc -l); echo "Duplicate reference names: $dups"
[ "$nf" = "$nm" ] && [ "$dups" = 0 ] || { echo "ERROR: counts differ or names repeat" >&2; exit 1; }
tar czf "$K.tar.gz" -C "$OUTDIR" "$(basename "$K")"; tar czf "$M.tar.gz" -C "$OUTDIR" "$(basename "$M")"
echo "Kraken2 package:  $K  (and $K.tar.gz)"
echo "minimap2 package: $M  (and $M.tar.gz)"

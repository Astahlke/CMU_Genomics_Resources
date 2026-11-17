#!/usr/bin/env bash
# Environment: kraken2 (kraken2 + bracken). Builds the Kraken2 database and Bracken files.
set -euo pipefail
source "${CONFIG:-config.sh}"
source "$(dirname "$0")/lib.sh"
require kraken2 kraken2-build bracken-build
DB="$OUTDIR/kraken_db"; FA="$OUTDIR/${MARKER}_clean.fasta"
if [ -d "$DB/library" ] && [ -n "$(ls -A "$DB/library" 2>/dev/null)" ]; then
  echo "ERROR: $DB/library already has sequences. Use a new OUTDIR for each marker." >&2
  echo "To redo this marker: rm -rf $DB/library $DB/*.k2d $DB/*.map $DB/*kmer_distrib $DB/*.kraken" >&2; exit 1
fi
FLAG=""; [ "$MASKING" = "no" ] && FLAG="--no-masking"     # confirm with: kraken2-build --help
kraken2-build --add-to-library "$FA" --db "$DB" $FLAG
kraken2-build --build --db "$DB" --threads "$THREADS"
for f in hash.k2d opts.k2d taxo.k2d; do [ -s "$DB/$f" ] || { echo "Build failed: $f missing" >&2; exit 1; }; done
for L in $BRACKEN_LENGTHS; do
  bracken-build -d "$DB" -t "$THREADS" -k "$KMER" -l "$L"
done
# Self-test: the reference should classify almost completely against itself
kraken2 --db "$DB" --threads "$THREADS" --report "$OUTDIR/self_test.kreport" --output /dev/null "$FA"
echo "Self-test report: $OUTDIR/self_test.kreport (first line = unclassified percentage)"; head -n 2 "$OUTDIR/self_test.kreport"

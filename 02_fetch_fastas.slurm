#!/bin/bash
#SBATCH --job-name=fetch_by_taxid
#SBATCH --partition=acpu
#SBATCH --qos=cpu-normal
#SBATCH --ntasks=2
#SBATCH --time=12:00:00
#SBATCH --output=fetch_by_taxid_%j.log
#
# 
# Input: [records.tsv] tab-separated table with a header and columns made with 01_fetch_by_accesion.sh
#   1 accession.version   2 taxid   3 species   4 length   5 title
# Steps:
#   1. keep ONE accession per TaxID (the longest sequence)            -> selected.tsv, accessions.txt
#   2. download those accessions in batches of 200 (resumable)       -> batches/*.fa, failed_batches.txt
#   3. write one FASTA per TaxID with a Kraken2 header               -> fasta_by_taxid/<taxid>.fasta
#      header:  >ACCESSION|kraken:taxid|TAXID  description
# Failed accessions are listed in failed_accessions.txt (withdrawn or unavailable records); the rest still download.
# Optional: set NCBI_API_KEY in your shell (export NCBI_API_KEY=...). 

## export NCBI_API_KEY=
module load miniforge
conda activate edirect


TSV="${1:-rbcL_records.tsv}"
BATCH="${BATCH:-200}"
OUT_DIR="${OUT_DIR:-fasta_by_taxid}"
mkdir -p batches "$OUT_DIR"
[ -s "$TSV" ] || { echo "Cannot read $TSV" >&2; exit 1; }
command -v efetch >/dev/null || { echo "efetch not found: conda activate edirect" >&2; exit 1; }
[ -n "${NCBI_API_KEY:-}" ] || echo "Warning: NCBI_API_KEY not set (3 requests/s limit)." >&2
 
# 1. one accession per TaxID: skip blank/NA TaxIDs, sort by TaxID then length (longest first), keep the first per TaxID
tail -n +2 "$TSV" \
  | awk -F'\t' '$1!="" && $2 ~ /^[0-9]+$/' \
  | sort -t$'\t' -k2,2n -k4,4nr \
  | awk -F'\t' '!seen[$2]++ {print $1 "\t" $2 "\t" $3 "\t" $4}' > selected.tsv
cut -f1 selected.tsv > accessions.txt
echo "TaxIDs (one accession each): $(wc -l < selected.tsv)   from $(( $(wc -l < "$TSV") - 1 )) records"
 
# 2. batched, resumable download
rm -f batches/batch_* 2>/dev/null; split -l "$BATCH" -d -a 5 accessions.txt batches/batch_
: > failed_batches.txt; : > failed_accessions.txt
for lst in batches/batch_?????; do
  fa="$lst.fa"
  [ -s "$fa" ] && continue
  ids=$(paste -sd, "$lst")
  ok=0
  for try in 1 2 3; do
    if efetch -db nuccore -id "$ids" -format fasta > "$fa.tmp" 2> "$lst.err" && [ -s "$fa.tmp" ]; then
      mv "$fa.tmp" "$fa"; ok=1; break
    fi
    sleep $((try * 5))
  done
  if [ "$ok" -eq 0 ]; then
    # one bad accession can sink a whole batch: retry this batch one accession at a time
    rm -f "$fa.tmp"; : > "$fa.tmp"
    while read -r acc; do
      if one=$(efetch -db nuccore -id "$acc" -format fasta 2>/dev/null) && [ -n "$one" ]; then
        printf '%s\n' "$one" >> "$fa.tmp"
      else
        echo "$acc" >> failed_accessions.txt
      fi
      sleep 0.2
    done < "$lst"
    if [ -s "$fa.tmp" ]; then mv "$fa.tmp" "$fa"; else rm -f "$fa.tmp"; echo "$lst" >> failed_batches.txt; fi
  fi
  sleep 0.2
done
if [ -s failed_batches.txt ]; then echo "Some batches failed: see failed_batches.txt, then rerun the script (finished batches are kept)." >&2; fis

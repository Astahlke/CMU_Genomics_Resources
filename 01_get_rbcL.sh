#!/bin/bash
## export NCBI_API_KEY=
## heavily inspired by https://github.com/bethk-h/custom-kraken2-database
module load anaconda

conda activate edirect
esearch -help                  # check the install worked


MINLEN=300; MAXLEN=1500; ORG='Viridiplantae[Organism]'     # or a taxa chunk
Q="(chloroplast[Title] OR plastid[Title] AND "complete genome"[Title] AND srcdb_refseq[PROP] AND $ORG)"
Q="(rbcL[Gene] OR rbcL[Title]) AND $ORG AND ${MINLEN}:${MAXLEN}[SLEN] NOT (PREDICTED[Title] OR UNVERIFIED[Title] OR environmental sample[Title])"
echo "$Q"      # check it looks complete first

printf 'accession\ttaxid\tspecies\tlength\ttitle\n' > records.tsv
esearch -db nuccore -query "$Q" | efetch -format docsum \
  | xtract -pattern DocumentSummary -def "NA" -element AccessionVersion TaxId Organism Slen Title >> records.tsv

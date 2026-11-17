# ---- Edit this file for each marker. Every script reads it. ----
MARKER=rbcL                         # short name; used in file names
OUTDIR="ref_${MARKER}"              # one folder per marker (never reuse one for another marker)

# NCBI search
ORG='Viridiplantae[Organism]'       # taxon filter
QUERY='(rbcL[Gene] OR rbcL[Title])' # marker part of the query (see notes in README for spacers)
EXTRA=''                            # optional extra filter, e.g. 'NOT uncultured[Title]'
MINLEN=300                          # sequence length window (bp); set from the length distribution
MAXLEN=1500
MAX_PER_TAXID=1                     # 1 for conserved genes; 3 for hypervariable spacers
BATCH=200                           # accessions per efetch request

# Taxonomy: path to an existing taxonomy/ folder to copy (recommended), or leave empty to download
TAXONOMY_FROM=""

# Kraken2 / Bracken
THREADS=8
KMER=35
BRACKEN_LENGTHS="200 450"           # read lengths to build Bracken files for
MASKING=yes                         # yes = default masking; no = add --no-masking

# Conda environments (created by 00_setup_envs.sh if missing)
ENV_REFBUILD=refbuild               # entrez-direct, seqkit, vsearch, mafft, python
ENV_KRAKEN2=kraken2                 # kraken2, bracken, seqkit, python

acompile
module load miniforge
eval "$(conda shell.bash hook)"        # use this instead of "mamba init"
conda config --add channels conda-forge
conda config --add channels bioconda
conda config --set channel_priority strict

conda create -y -n refbuild entrez-direct seqkit vsearch mafft python=3.11
conda create -y -n kraken2 kraken2 bracken seqkit

#!/bin/bash
#SBATCH --job-name=refpipe
#SBATCH --partition=acpu
#SBATCH --qos=cpu-normal
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=refpipe_%j.log
# Submit from the refpipe folder:  sbatch run_all.sbatch      (edit config.sh first)
# Export NCBI_API_KEY in your ~/.bashrc if you have one (do not paste it into this file).
set -eo pipefail
module load miniforge
eval "$(conda shell.bash hook)"
cd "$SLURM_SUBMIT_DIR"
export CONFIG=config.sh
source "$CONFIG"             # for ENV_REFBUILD and ENV_KRAKEN2

bash 00_setup_envs.sh        # checks the environments and installs anything missing

conda activate "$ENV_REFBUILD"
bash 01_fetch_records.sh
bash 02_select.sh
bash 03_fetch_fasta.sh
conda deactivate

conda activate "$ENV_KRAKEN2"
bash 04_taxonomy.sh
bash 05_check_taxids.sh
bash 06_build_kraken.sh
bash 07_package_for_epi2me.sh
conda deactivate
echo "Done."

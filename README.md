# CMU Genomics Resources
This repo will help onboard students and collect common solutions to HPC programming at Colorado Mesa University, mostly built from experience with BIOL 496: Experiments in Genomics

# Where do I run things?
- **Login node** (where you land): edit files, copy files, submit jobs. Do not run analyses here.
- **`acompile`**: a short session for setting up software (conda environments, `module load`).
- **`sinteractive`**: a session on a compute node for running tools while you watch.
- **`sbatch`**: for anything long or unattended.

Always type `exit` when you finish an interactive session.

# For example, how to initiate a short and sweet interactive job that will only last 1 hr
`sinteractive --partition=acpu --time=00:60:00 --ntasks=1 --nodes=1 --qos=cpu-normal`

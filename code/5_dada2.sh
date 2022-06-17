#!/bin/bash
#SBATCH --job-name=5_dada2
#SBATCH --partition scavenger
#SBATCH --mem=64000
#SBATCH -n 2  # Number of cores
#SBATCH --out=5_dada2-%j.out
#SBATCH --error=5_dada2-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END

# Usage: 5_dada2.sh /marker-dir input output,  
# where marker-dir is the directory containing reads that all share the same 
# primer set (can group together as dada2 infers variants) 

module load Anaconda3/5.1.0
module load R/4.1.1-rhel8
source activate /hpc/group/ldavidlab/modules/qiime2-env

## Make output folders (can't figure out how to do this in R script)
# mkdir $1/$3 

# Run dada2
cd /hpc/group/ldavidlab/scripts/mb-pipeline/code
Rscript 5_Rscript-echo.R 5_dada2.R $1 $2 $3 

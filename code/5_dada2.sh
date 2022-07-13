#!/bin/bash
#SBATCH --job-name=5_dada2
#SBATCH --partition scavenger
#SBATCH --mem=64000
#SBATCH -n 2  # Number of cores
#SBATCH --out=5_dada2-%j.out
#SBATCH --error=5_dada2-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END

# Usage: 5_dada2.sh /marker-dir input output /container-dir
# where marker-dir is the directory containing reads that all share the same 
# primer set (can group together as dada2 infers variants) 
# Example: sbatch --mail-user=youremail@duke.edu 5_dada2.sh /path/to/XXXXXXXX_results 3_trimprimer 4_dada2output /path/to/metabarcoding.sif

## Make output folders (can't figure out how to do this in R script)
mkdir $1/$3 

# Run dada2
singularity exec --bind $1,$PWD $4 Rscript 5_Rscript-echo.R 5_dada2.R $1 $2 $3

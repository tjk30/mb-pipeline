#!/bin/bash
#SBATCH --job-name=5_dada2
#SBATCH --partition scavenger
#SBATCH --mem=64000
#SBATCH -n 2  # Number of cores
#SBATCH --out=5_dada2.out
#SBATCH --error=5_dada2.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END

# Usage: 5_dada2.sh /marker-dir runType /container-dir
# where marker-dir is the directory containing reads that all share the same 
# primer set (can group together as dada2 infers variants) 
# Example: sbatch --mail-user=youremail@duke.edu 5_dada2.sh /path/to/XXXXXXXX_results trnL /path/to/metabarcoding.sif

## Make output folders 
mkdir $1/4_dada2output

# Run dada2
singularity exec --bind $1,$PWD $3 Rscript 5_Rscript-echo.R 5_dada2.R $1 $2 

# cleanup
mv 5_dada2.out $1/Reports
mv 5_dada2.err $1/Reports

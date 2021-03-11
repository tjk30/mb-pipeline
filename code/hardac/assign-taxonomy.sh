#!/bin/bash
#SBATCH --job-name=assign-taxonomy
#SBATCH --mem=20000
#SBATCH --out=reports/assign-taxonomy-%j.out
#SBATCH --error=reports/assign-taxonomy-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --mail-user=blp23@duke.edu

# Usage: assign-taxonomy.sh /marker-dir /path/to/reference.fasta outdir,  
# where marker-dir is the directory containing reads that all share the same 
# primer set (can group together as dada2 infers variants) 

module load gcc/5.3.0-fasrc01
module load R/3.4.0-gcb01
module load lapack/3.6.1-gcb01

# Run R script 
cd ~/scripts
Rscript Rscript-echo.R assign-taxonomy.R $1 $2 $3 

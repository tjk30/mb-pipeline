#!/bin/bash
#SBATCH --job-name=5_dada2
#SBATCH --mem=40000
#SBATCH -n 2  # Number of cores
#SBATCH --out=reports/5_dada2-%j.out
#SBATCH --error=reports/5_dada2-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --mail-user=blp23@duke.edu

# Usage: 5_dada2.sh /marker-dir input output,  
# where marker-dir is the directory containing reads that all share the same 
# primer set (can group together as dada2 infers variants) 

cd /data/common/qiime2
source miniconda/bin/activate qiime2-2019.10

## Make output folders (can't figure out how to do this in R script)
# mkdir $1/$3 

# Run dada2
cd ~/scripts
Rscript 5_Rscript-echo.R 5_dada2.R $1 $2 $3 

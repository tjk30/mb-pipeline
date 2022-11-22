#!/bin/bash
#SBATCH -J count-reads
#SBATCH --partition scavenger
#SBATCH --mem=10000
#SBATCH --output=count-reads.out
#SBATCH --error=count-reads.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END

# USAGE: sbatch --mail-user=youremail@duke.edu count-reads.sh /path/to/XXXXXXXX_results /path/to/metabarcoding.sif
# load R via container 
singularity exec --bind $1,$PWD $2 Rscript count-reads.R $1

# move .err and .out files
mv $PWD/count-reads.out $1/Reports
mv $PWD/count-reads.err $1/Reports

#!/bin/bash
#SBATCH --job-name=demux-adapter
#SBATCH --mem=20000
#SBATCH --out=reports/demux-adapter-%j.out
#SBATCH --error=reports/demux-adapter-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --mail-user=blp23@duke.edu

# Usage: demux-adapter.sh /miniseq-dir samplesheetname
# This assumes that the sample sheet is located in the parent directory containing the MiniSeq results
# folder

module load bcl2fastq2 

cd $1

now=$(date +'%Y%m%d')
outdir=$now'_results'
mkdir $outdir

bcl2fastq -o $outdir --interop-dir InterOp/$now --stats-dir Stats/$now --reports-dir Reports/$now --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --sample-sheet ../$2

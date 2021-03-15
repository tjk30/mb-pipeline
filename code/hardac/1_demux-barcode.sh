#!/bin/bash
#SBATCH --job-name=1_demux-barcode
#SBATCH --mem=20000
#SBATCH --out=reports/1_demux-barcode-%j.out
#SBATCH --error=reports/1_demux-barcode-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --mail-user=blp23@duke.edu

# Usage: demux-barcode.sh /miniseq-dir samplesheetname
# This assumes that the sample sheet is located in the parent directory containing the MiniSeq results
# folder

module load bcl2fastq2 

cd $1

now=$(date +'%Y%m%d')
outdir=$now'_results'
mkdir $outdir

# Demultiplex
bcl2fastq -o $outdir --interop-dir InterOp/$now --stats-dir Stats/$now --reports-dir Reports/$now --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --sample-sheet ../$2

# Clean up directory structure
mkdir $outdir/0_raw_demux
mv $outdir/*.fastq.gz $outdir/0_raw_demux/

# Convert, but don't demultiplex (amalgamated data used for downstream quality plot)
# R: runfolder dir
bcl2fastq -R . -o $outdir

# Clean up directory structure
mkdir $outdir/0_raw_all
mv $outdir/*.fastq.gz $outdir/0_raw_all/

# Remove duplicate Reports and Stats directories
rm -r $outdir/Reports $outdir/Stats

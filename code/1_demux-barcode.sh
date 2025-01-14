#!/bin/bash
#SBATCH --job-name=1_demux-barcode
#SBATCH --mem=20000
#SBATCH --partition scavenger 
#SBATCH --out=1_demux-barcode.out
#SBATCH --error=1_demux-barcode.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END

# Usage: 1_demux-barcode.sh /container-dir /miniseq-dir samplesheetname runType
# Example: sbatch --mail-user=youremail@duke.edu 1_demux-barcode.sh /path/to/metabarcoding.sif path/to/miniseq-dir XXXXXXXX_sample-sheet.csv 
# This assumes that the sample sheet is located in the parent directory containing the MiniSeq results
# folder
codedir=$PWD
cd $2
cd ..
parent=$PWD
now=$(date +'%Y%m%d')
resFolder=$now'_results'
outdir=$parent/$resFolder
mkdir $outdir

cd $2
# Demultiplex
singularity exec --bind $parent $1 bcl2fastq -o $outdir --interop-dir InterOp/$now --stats-dir Stats/$now --reports-dir Reports/$now --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 --sample-sheet $parent/$3

# Clean up directory structure
mkdir $outdir/0_raw_demux
mv $outdir/*.fastq.gz $outdir/0_raw_demux/

# Convert, but don't demultiplex (amalgamated data used for downstream quality plot)
# R: runfolder dir
singularity exec --bind $parent $1 bcl2fastq -R . -o $outdir

# Clean up directory structure
mkdir $outdir/0_raw_all
mv $outdir/*.fastq.gz $outdir/0_raw_all/

# Remove duplicate Reports and Stats directories
rm -r $outdir/Reports $outdir/Stats

# move .out and .err files
mkdir $outdir/Reports
mv $codedir/1_demux-barcode.out $outdir/Reports
mv $codedir/1_demux-barcode.err $outdir/Reports

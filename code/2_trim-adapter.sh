#!/bin/bash
#SBATCH --job-name=2_trim-adapter
#SBATCH --partition scavenger
#SBATCH --mem=20000
#SBATCH --out=2_trim-adapter.out
#SBATCH --error=2_trim-adapter.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END


# Usage: 2_trim-adapter.sh /container-dir /marker-dir
  # Example: sbatch --mail-user=youremail@duke.edu 2_trim-adapter.sh /path/to/metabarcoding.sif path/to/XXXXXXXX_results 
# where marker-dir is the directory containing reads that all share the same
# primer set
# This trims off read-through into Illumina adapter at the 3' side of the read,
# which can occur if the amplicon size is <150 bp.
codedir=$PWD
cd $2
cd ..
wd=$PWD
mkdir $2/1_trimadapter
cd $2/0_raw_demux

for read1 in *R1_001.fastq.gz; do
    # Find its matched read 2
    read2=${read1%R1_001.fastq.gz}R2_001.fastq.gz

    # Perform adapter trimming with BBDuk
    singularity exec --bind $wd $1 bbduk.sh in1=$read1 in2=$read2 \
	literal=CTGTCTCTTATACACATCT out1=../1_trimadapter/$read1 \
	out2=../1_trimadapter/$read2 \
	ktrim=r k=19 mink=11 hdist=3 tbo tpe \
	&>> ../1_trimadapter/BBDuk.out
done
# move .out and .err files
mv $codedir/2_trim-adapter.out $2/Reports
mv $codedir/2_trim-adapter.err $2/Reports

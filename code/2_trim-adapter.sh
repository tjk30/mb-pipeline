#!/bin/bash
#SBATCH --job-name=2_trim-adapter
#SBATCH --partition scavenger
#SBATCH --mem=20000
#SBATCH --out=2_trim-adapter-%j.out
#SBATCH --error=2_trim-adapter-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END

# Usage: trim-adapter.sh /marker-dir
# where marker-dir is the directory containing reads that all share the same
# primer set
# This trims off read-through into Illumina adapter at the 3' side of the read,
# which can occur if the amplicon size is <150 bp.

module load BBMap/38.63
mkdir $1/1_trimadapter
cd $1/0_raw_demux

for read1 in *R1_001.fastq.gz; do
	# Find its matched read 2
	read2=${read1%R1_001.fastq.gz}R2_001.fastq.gz

	# Perform adapter trimming with BBDuk
	/opt/apps/rhel7/bbmap/bbduk.sh in1=$read1 in2=$read2 \
	literal=CTGTCTCTTATACACATCT out1=../1_trimadapter/$read1 \
	out2=../1_trimadapter/$read2 \
	ktrim=r k=19 mink=11 hdist=3 tbo tpe \
	&>> ../1_trimadapter/BBDuk.out
done


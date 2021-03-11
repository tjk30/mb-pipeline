#!/bin/bash
#SBATCH --job-name=trim-adapter
#SBATCH --mem=20000
#SBATCH --out=reports/trim-adapter-%j.out
#SBATCH --error=reports/trim-adapter-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --mail-user=blp23@duke.edu

# Usage: trim-adapter.sh /marker-dir
# where marker-dir is the directory containing reads that all share the same
# primer set
# This trims off read-through into Illumina adapter at the 3' side of the read,
# which can occur if the amplicon size is <150 bp.
# Also runs fastQC on reads pre- and post-trimming.

module load fastqc

mkdir $1/1_trimadapter
cd $1/0_raw
# Initial QC
mkdir fastqc
fastqc *.fastq.gz -o fastqc/

for read1 in *R1_001.fastq.gz; do
	# Find its matched read 2
	read2=${read1%R1_001.fastq.gz}R2_001.fastq.gz

	# Perform adapter trimming with BBDuk
	~/bin/bbmap/bbduk.sh in1=$read1 in2=$read2 \
	literal=CTGTCTCTTATACACATCT out1=../1_trimadapter/$read1 \
	out2=../1_trimadapter/$read2 \
	ktrim=r k=19 mink=11 hdist=3 tbo tpe \
	&>> ../1_trimadapter/BBDuk.out
done

cd ../1_trimadapter
# Now that adapters trimmed, repeat QC
mkdir fastqc
fastqc *.fastq.gz -o fastqc/

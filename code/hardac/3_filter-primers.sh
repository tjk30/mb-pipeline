#!/bin/bash
#SBATCH --job-name=3_filter-primers
#SBATCH --mem=20000
#SBATCH --out=reports/3_filter-primers-%j.out
#SBATCH --error=reports/3_filter-primers-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --mail-user=blp23@duke.edu

# Load cutadapt in conda environment
source /data/davidlab/packages/miniconda3/etc/profile.d/conda.sh
conda activate base

cd $1
mkdir 2_filter

# Read in primer sequences from file (on separate lines in order: forward, reverse)
{ IFS= read -r fwd && IFS= read -r rev; } < 0_reference/primers.txt

for read1 in 1_trimadapter/*_R1_*; do
	read2=${read1%R1_001.fastq.gz}R2_001.fastq.gz # Find its matched read 2

	fullname=${read1#1_trimadapter}
	name=${fullname//_[^.]*/} # This pulls the name of the file, minus MiniSeq-added info

	# Do paired-end filtering: Both R1 and R2 must have the correct amplicon primer anchored at 5' end
	cutadapt \
	--overlap 5 -e 0.15 \
	--action=none --discard-untrimmed --pair-filter=any \
	-g $fwd \
	-G $rev \
	-o 2_filter/${name}_R1.fastq.gz -p 2_filter/${name}_R2.fastq.gz \
	$read1 $read2 \
	> 2_filter/$name.out
done

#!/bin/bash
#SBATCH --job-name=trim-primers
#SBATCH --mem=20000
#SBATCH --out=reports/trim-primers-%j.out
#SBATCH --error=reports/trim-primers-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --mail-user=blp23@duke.edu

# Usage: trim-primers.sh /marker-dir 
# where marker-dir is the directory containing reads that all share the same 
# primer set 

# Go to amplicon directory
cd $1
mkdir 3_trimprimer

# Read in primer sequences from file (in order: forward; reverse; reverse complement of forward; and reverse complement of reverse)
{ IFS= read -r fwd && IFS= read -r rev && IFS= read -r fwdrc && IFS= read -r revrc; } < 0_reference/primers.txt

# Remove forward and reverse primer from paired-end reads
for read1 in 2_*/*_R1.fastq.gz; do
	read2=${read1%R1.fastq.gz}R2.fastq.gz # Find its matched read 2
	# This pulls the sample name, here [primer]-30-pool or [primer]-NTC in order 
	# to carry it over to the output filename
	regex='([^_]*)(_.*)' # Match up to first underscore to get name
	name=$([[ ${read1##*/} =~ $regex ]] && echo "${BASH_REMATCH[1]}") # 1st capture grp
	suffix1=$([[ ${read1##*/} =~ $regex ]] && echo "${BASH_REMATCH[2]}") # 2nd capture grp
	suffix2=$([[ ${read2##*/} =~ $regex ]] && echo "${BASH_REMATCH[2]}") # 2nd capture grp
	
	# Perform paired-end trimming with cutadapt:
	# Here, we always want to trim the leading forward primer
	# And if the read is short enough, we may read into the reverse primer, and want to trim that too.
	# Parameter settings as follows
	# Specifying a linked adapter with -a makes the adapters that are anchored  required, and the non-anchored
	# adapters  optional. -g makes both adapters required
	# -a: Trim adapter from forward read
	# -A: Trim adapter from reverse read 
	# -o: The output file
	# -p: The short form of 'paired output', a second output file alongside the normal -o output
	# --minimum-length: Set this parameter so cutadapt doesn't preserve empty reads (length 0) in output,
	# which can't be handled by DADA2

	/data/davidlab/packages/cutadapt/miniconda3/bin/cutadapt \
	--minimum-length 1 --discard-untrimmed \
	-a "^${fwd:0};e=0.15...$revrc;e=0.15" \
	-A "^${rev:0};e=0.15...$fwdrc;e=0.15" \
	-o 3_trimprimer/$name$suffix1 -p 3_trimprimer/$name$suffix2 \
	$read1 $read2 \
	> 3_trimprimer/$name.out

done

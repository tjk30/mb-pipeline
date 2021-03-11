#!/bin/bash
#SBATCH --job-name=trim-adapter
#SBATCH --mem=20000
#SBATCH --out=reports/trim-adapter-%j.out
#SBATCH --error=reports/trim-adapter-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --mail-user=blp23@duke.edu

# Usage: singleplex-pipeline.sh /marker-dir

# TRIM READ-THROUGH INTO ILLUMINA ADAPTER 
# This trims off read-through into Illumina adapter at the 3' side of the read,
# which can occur if the amplicon size is <150 bp.
# Also runs fastQC on reads pre- and post-trimming.

mkdir $1/1_trimadapter
cd $1/0_raw

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

# LOOK FOR PRIMER SETS IN READ

cd $1
mkdir 2_filter

# Read in primer sequences from file (on separate lines in order: forward, reverse)
{ IFS= read -r fwd && IFS= read -r rev; } < 0_reference/primers.txt

for read1 in 1_trimadapter/*_R1_*; do
	read2=${read1%R1_001.fastq.gz}R2_001.fastq.gz # Find its matched read 2

	fullname=${read1#1_trimadapter}
	name=${fullname//_[^.]*/} # This pulls the name of the file, minus MiniSeq-added info

	# Do paired-end filtering: Both R1 and R2 must have the correct amplicon primer anchored at 5' end
	/data/davidlab/packages/cutadapt/miniconda3/bin/cutadapt \
	--overlap 5 -e 0.15 \
	--action=none --discard-untrimmed --pair-filter=any \
	-g $fwd \
	-G $rev \
	-o 2_filter/${name}_R1.fastq.gz -p 2_filter/${name}_R2.fastq.gz \
	$read1 $read2 \
	> 2_filter/$name.out
done

# TRIM PRIMERS FROM READ

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

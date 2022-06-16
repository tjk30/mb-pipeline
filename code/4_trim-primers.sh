#!/bin/bash
#SBATCH --job-name=4_trim-primers
#SBATCH --partition scavenger
#SBATCH --mem=20000
#SBATCH --out=reports/4_trim-primers-%j.out
#SBATCH --error=reports/4_trim-primers-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END

# Usage: trim-primers.sh /marker-dir 
# where marker-dir is the directory containing reads that all share the same 
# primer set 

module load Anaconda3/5.1.0
source activate /hpc/group/ldavidlab/modules/cutadapt-env

# Go to amplicon directory
cd $1
mkdir 3_trimprimer

# Read in primer sequences from file 
# (in order: 
#  forward
#  reverse
#  reverse complement of forward
#  reverse complement of reverse
# )
{ IFS= read -r fwd && IFS= read -r rev && IFS= read -r fwdrc && IFS= read -r revrc; } < \
	0_reference/primers.txt

# Determine if analyzing one read or two
# Is R1 missing? 
if ! ls 2_filter/*_R1.fastq.gz 1> /dev/null 2>&1; then
	echo "R1 does not exist, analyzing R2 only"
	for read2 in 2_filter/*_R2.fastq.gz; do 
		fullname=${read2#2_filter/}
		name=${fullname//_[^.]*/} # Pull filename without MiniSeq-added info

		# Do single-end trimming:
		# Always trim the leading forward primer, and if the read is short enough to read
		# into the reverse primer, remove that as well.
		#		
		# Parameters:
		# Specifying a linked adapter with -a makes the adapters that are anchored 
		# required, and the non-anchored adapters  optional. 
		# -a: Trim adapter from forward read
		# -o: The output file
		# --minimum-length: Set this parameter so cutadapt doesn't preserve empty reads 
		# (length 0) in output, which can't be handled by DADA2

		cutadapt \
		--minimum-length 1 --discard-untrimmed \
		-a "^${rev:0};e=0.15...$fwdrc;e=0.15" \
		-o 3_trimprimer/$fullname $read2 \
		> 3_trimprimer/$name.out	
	done
# Is R2 missing?  
elif ! ls 2_filter/*_R2.fastq.gz 1> /dev/null 2>&1; then
	echo "R2 does not exist, analyzing R1 only"
	for read1 in 2_filter/*_R1.fastq.gz; do 
		fullname=${read1#2_filter/}
		name=${fullname//_[^.]*/} # Pull filename without MiniSeq-added info

		# Do single-end trimming:
		# R1 must have the correct amplicon primer anchored at 5' end
		cutadapt \
		--minimum-length 1 --discard-untrimmed \
		-a "^${fwd:0};e=0.15...$revrc;e=0.15" \
		-o 3_trimprimer/$fullname $read1 \
		> 3_trimprimer/$name.out	
	done
# Both reads present, perform paired-end trimming
else
	for read1 in 2*/*_R1.fastq.gz; do
		read2=${read1%R1.fastq.gz}R2.fastq.gz # Find its matched read 2
		regex='([^_]*)(_.*)' # Match up to first underscore to get name
		# 1st capture group
		name=$([[ ${read1##*/} =~ $regex ]] && echo "${BASH_REMATCH[1]}")
		# 2nd capture group
		suffix1=$([[ ${read1##*/} =~ $regex ]] && echo "${BASH_REMATCH[2]}")
	        # 2nd capture group	
		suffix2=$([[ ${read2##*/} =~ $regex ]] && echo "${BASH_REMATCH[2]}")
		
		# Perform paired-end trimming with cutadapt:
		# -a: Trim adapter from forward read
		# -A: Trim adapter from reverse read 
		# -o: The output file
		# -p: The short form of 'paired output', a second output file alongside the normal -o output
		# --minimum-length: Minimum length of reads preserved by cutadapt
		cutadapt \
		--minimum-length 1 --discard-untrimmed \
		-a "^${fwd:0};e=0.15...$revrc;e=0.15" \
		-A "^${rev:0};e=0.15...$fwdrc;e=0.15" \
		-o 3_trimprimer/$name$suffix1 -p 3_trimprimer/$name$suffix2 \
		$read1 $read2 \
		> 3_trimprimer/$name.out

	done
fi

conda deactivate # Close conda environment

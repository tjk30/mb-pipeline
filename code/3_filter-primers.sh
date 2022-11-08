#!/bin/bash
#SBATCH --job-name=3_filter-primers
#SBATCH --partition scavenger
#SBATCH --mem=20000
#SBATCH --out=3_filter-primers.out
#SBATCH --error=3_filter-primers.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END

# Usage: sbatch --mail-user=youremail@duke.edu 3_filter-primers.sh /path/to/metabarcoding.sif path/to/XXXXXXXX_results
codedir=$PWD
cd $2
mkdir 2_filter

# Read in primer sequences from file (on separate lines in order: forward, reverse)
{ IFS= read -r fwd && IFS= read -r rev; } < 0_reference/primers.txt

# Determine if analyzing one read or two
# Is R1 missing? 
if ! ls 1_trimadapter/*_R1_* 1> /dev/null 2>&1; then
	echo "R1 does not exist, analyzing R2 only"
	for read2 in 1_trimadapter/*_R2_*; do 
		fullname=${read2#1_trimadapter/}
		name=${fullname//_[^.]*/} # Pull filename without MiniSeq-added info

		# Do single-end filtering:
		# R2 must have the correct amplicon primer anchored at 5' end
		singularity exec --bind $2 $1 cutadapt \
		--overlap 5 -e 0.15 \
		--action=none --discard-untrimmed \
		-g $rev -o 2_filter/${name}_R2.fastq.gz $read2 \
		> 2_filter/$name.out
	done
# Is R2 missing?  
elif ! ls 1_trimadapter/*_R2_* 1> /dev/null 2>&1; then
	echo "R2 does not exist, analyzing R1 only"
	for read1 in 1_trimadapter/*_R1_*; do 
		fullname=${read1#1_trimadapter/}
		name=${fullname//_[^.]*/} # Pull filename without MiniSeq-added info

		# Do single-end filtering:
		# R1 must have the correct amplicon primer anchored at 5' end
		singularity exec --bind $2 $1 cutadapt \
		--overlap 5 -e 0.15 \
		--action=none --discard-untrimmed \
		-g $fwd -o 2_filter/${name}_R1.fastq.gz $read1 \
		> 2_filter/$name.out
	done

else 
	# Data is paired-end; analyze both files
	echo "Analyzing paired-end data"

	for read1 in 1_trimadapter/*_R1_*; do
		read2=${read1%R1_001.fastq.gz}R2_001.fastq.gz # Find its matched read 2

		fullname=${read1#1_trimadapter}
		name=${fullname//_[^.]*/} # Pull filename without MiniSeq-added info

		# Do paired-end filtering: Both R1 and R2 must have the correct amplicon primer 
		# anchored at 5' end
		singularity exec --bind $2 $1 cutadapt \
		--overlap 5 -e 0.15 \
		--action=none --discard-untrimmed --pair-filter=any \
		-g $fwd \
		-G $rev \
		-o 2_filter/${name}_R1.fastq.gz -p 2_filter/${name}_R2.fastq.gz \
		$read1 $read2 \
		> 2_filter/$name.out
	done
fi

# move output files
mv $codedir/3_filter-primers.out $2/Reports
mv $codedir/3_filter-primers.err $2/Reports

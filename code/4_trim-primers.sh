#!/bin/bash
#SBATCH --job-name=4_trim-primers
#SBATCH --partition scavenger
#SBATCH --mem=20000
#SBATCH --out=4_trim-primers.out
#SBATCH --error=4_trim-primers.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END

# Usage: trim-primers.sh /container-dir /marker-dir runType
# where marker-dir is the directory containing reads that all share the same primer set 
# and runType is if you are trimming 12SV5 or trnL primers
# Example: sbatch --mail-user=youremail@duke.edu 4_trim-primers.sh /path/to/metabarcoding.sif path/to/XXXXXXXX_results <trnL>OR<12SV5>
$codedir=$PWD
# Go to amplicon directory
cd $2
$outdir='3_trimprimer_'$3
mkdir $outdir
mkdir 0_reference

if [[ "$3" = "trnL" ]]
then
echo "You have selected trnL as your run type"
echo "GGGCAATCCTGAGCCAA 
CCATTGAGTCTCTGCACCTATC
TTGGCTCAGGATTGCCC
GATAGGTGCAGAGACTCAATGG" >> 0_reference/primers.txt #these are the trnLGH primer sequences
elif [[ "$3" = "12SV5" ]]
then
echo "You have selected 12SV5 as your run type"
echo "TAGAACAGGCTCCTCTAG
TTAGATACCCCACTATGC
CTAGAGGAGCCTGTTCTA
GCATAGTGGGGTATCTAA" >> 0_reference/primers.txt #these are 12SV5 primers
else
echo "ERROR: please enter exactly 'trnL' or '12SV5' as your run type"
fi

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

		singularity exec --bind $2 $1 cutadapt \
		--minimum-length 1 --discard-untrimmed \
		-a "^${rev:0};e=0.15...$fwdrc;e=0.15" \
		-o $outdir/$fullname $read2 \
		> $outdir/$name.out	
	done
# Is R2 missing?  
elif ! ls 2_filter/*_R2.fastq.gz 1> /dev/null 2>&1; then
	echo "R2 does not exist, analyzing R1 only"
	for read1 in 2_filter/*_R1.fastq.gz; do 
		fullname=${read1#2_filter/}
		name=${fullname//_[^.]*/} # Pull filename without MiniSeq-added info

		# Do single-end trimming:
		# R1 must have the correct amplicon primer anchored at 5' end
		singularity exec --bind $2 $1 cutadapt \
		--minimum-length 1 --discard-untrimmed \
		-a "^${fwd:0};e=0.15...$revrc;e=0.15" \
		-o $outdir/$fullname $read1 \
		> $outdir/$name.out	
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
		singularity exec --bind $2 $1 cutadapt \
		--minimum-length 1 --discard-untrimmed \
		-a "^${fwd:0};e=0.15...$revrc;e=0.15" \
		-A "^${rev:0};e=0.15...$fwdrc;e=0.15" \
		-o $outdir/$name$suffix1 -p $outdir/$name$suffix2 \
		$read1 $read2 \
		> $outdir/$name.out

	done
fi
# cleanup
mv $codedir/4_trim-primers.out $2/Reports
mv $codedir/4_trim-primers.err $2/Reports

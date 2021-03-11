#!/bin/bash
#SBATCH --job-name=split-amplicons
#SBATCH --mem=20000
#SBATCH --out=reports/split-amplicons-%j.out
#SBATCH --error=reports/split-amplicons-%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --mail-user=blp23@duke.edu

cd $1
mkdir 2_demux

for read1 in 1_trimadapter/*--*_R1_*; do # This identifies barcodes that have multiplexed amplicons
  # STOP: regex needs to be adjusted based on the naming convention of the samples
	# 2019/12: This pulls the suffix, here -[SAMPLE#]-[ANNEALING TEMP] associated with the amplicon, to
	# carry it over to the output filename
	regex='[^-]*-([^-]*-[^-]*)--'
	suffix=$([[ $read1 =~ $regex ]] && echo "${BASH_REMATCH[1]}") # Pull 1st capture group
	fullname=${read1#1_trimadapter/}
	name=${fullname//_[^.]*/} # This pulls the name of the file, minus MiniSeq-added info
	amplicon=$(basename $1) # This pulls the amplicon name from the folder we're in
	
	read2=${read1%R1_001.fastq.gz}R2_001.fastq.gz # Find its matched read 2

	# Do paired-end filtering: Both R1 and R2 must have the correct amplicon primer anchored at 5' end
	/data/davidlab/packages/cutadapt/miniconda3/bin/cutadapt \
	--overlap 5 -e 0.15 \
	--action=none --discard-untrimmed --pair-filter=any \
	-g file:0_reference/barcodes_fwd.fasta \
	-G file:0_reference/barcodes_rev.fasta \
	-o 2_demux/${amplicon}-${suffix}_R1.fastq.gz -p 2_demux/${amplicon}-${suffix}_R2.fastq.gz \
	$read1 $read2 \
	> 2_demux/$name.out
done

mkdir 3_repair
# Now, repair mismatched reads in cutadapt output using repair.sh from BBTools
# This only has to be done for correctly identified reads, not for unknowns:
# for read1 in 2_demux/[!unknown]*_R1_001.fastq.gz; do # Consider read 1
# Had strange error where this wasn't recognizing nucLSUD-prefixed name, revised
for read1 in 2_demux/*R1_001.fastq.gz; do
      read2=${read1%R1_001.fastq.gz}R2_001.fastq.gz # Find its matched read 2
      regex='([^_]*)' # Match the primer-template name to pass to output file
      outfile=$([[ ${read1##*/} =~ $regex ]] && echo "${BASH_REMATCH[1]}")
      
      ~/bin/bbmap/repair.sh in1=$read1 in2=$read2 \
      out1=${read1/#2_demux/3_repair} out2=${read2/#2_demux/3_repair} \
      outs=3_repair/$outfile-singletons.fastq.gz repair \
      &> 3_repair/$outfile.out
done

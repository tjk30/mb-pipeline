#!/bin/bash
#SBATCH -J batch_asvs				# Job name
#SBATCH -p all						# Partition to run job
#SBATCH -N 1 						# Number of nodes
#SBATCH --mem 20000 				# Memory required per node in MB
#SBATCH -o batchjob_%j.out 			# STDOUT (with jobid = %j)
#SBATCH -e batchjob_%j.err 			# STDERR (with jobid = %j)
#SBATCH --mail-type=ALL				# Type of email notification: BEGIN, END, FAIL, ALL
#SBATCH --mail-user=blp23@duke.edu	# Email where notifications will be sent

module load ncbi-blast
export BLASTDB=/data/davidlab/users/blp23/BLASTdb

# Removed -max_target_seqs parameter after finding this does not always select sequences
# in order of best match to query, is dependent on database structure

# Need to read/update masking parameters; leaving off for now given animal sequences

for i in /data/davidlab/users/blp23/seqdata/asv/*.fasta; do
	name=`echo $i | awk -F "." '{print $1}'`
	srun blastn -db nt -query $i -out ${name}_masked.txt \
		-outfmt "6 qseqid sseqid pident qlen length mismatch gapopen evalue bitscore sacc staxids sscinames scomnames"
done


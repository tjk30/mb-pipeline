# Use DADA2's built-in taxonomic assignment functions

args <- commandArgs(trailingOnly=TRUE)
print(args)

setwd(args[2]) 
parent <- getwd()
reference <- args[3]
outdir <- args[4]

library(dada2); packageVersion('dada2')
library(ggplot2); packageVersion('ggplot2')

# Find filenames ----------------------------------------------------------

# Set directory for starting files: 
path <- file.path(parent, indir)

# Generate matched lists of forward and reverse filenames
fnFs <- sort(list.files(path, pattern = "R1_001.fastq.gz", full.names = TRUE))
fnRs <- sort(list.files(path, pattern = "R2_001.fastq.gz", full.names = TRUE))

# Extract sample names, assuming filenames have format:
get_sample_name <- function(fname) strsplit(basename(fname), "_")[[1]][1]
sample_names <- unname(sapply(fnFs, get_sample_name))
head(sample_names)

# Filter ------------------------------------------------------------------

# TODO: Visualize read quality? Or do beforehand with FastQC?
# Put N-filtered files in filtN/ subdirectory
fnFs_filtN <- file.path(path, "filtN", basename(fnFs)) 
fnRs_filtN <- file.path(path, "filtN", basename(fnRs))

out <- filterAndTrim(fnFs, fnFs_filtN, fnRs, fnRs_filtN, 
                     maxN = 0, 
                     maxEE = 2,
                     truncQ = 2, 
                     minLen = 10, # Setting this because min length of P6 is 10
                     rm.phix = TRUE, compress = TRUE, multithread = TRUE)  

head(out)

# Dereplication -----------------------------------------------------------

# Learn Error Rates
# Update path to output directory
path <- file.path(parent, outdir)
# if (!dir.exists(path)){
#      dir.create(path)
# }
setwd(path)

# Note that here verbose = FALSE by default, which is actually minimal text 
# output.  No text output is set by verbose = 0, and minimal output by 
# verbose = 1 or FALSE, detailed output by verbose = 2 or TRUE).
errF <- learnErrors(fnFs_filtN, multithread = TRUE, verbose=1)
errR <- learnErrors(fnRs_filtN, multithread = TRUE, verbose=1)

# Visualize estimated error rates
p <- plotErrors(errF, nominalQ = TRUE)
ggsave("dada_errors_F.png", plot = p)
p <- plotErrors(errR, nominalQ = TRUE)
ggsave("dada_errors_R.png", plot = p)

# Dereplicate identical reads
derepFs <- derepFastq(fnFs_filtN, verbose = TRUE)
derepRs <- derepFastq(fnRs_filtN, verbose = TRUE)

# Name the derep-class objects by the sample names
names(derepFs) <- sample_names
names(derepRs) <- sample_names

# Sample Inference --------------------------------------------------------

# Apply core sample inference algorithm to dereplicated sequences
# Save R objects throughout to allow return to data if follow-up needed

dadaFs <- dada(derepFs, err = errF, multithread = TRUE)
dadaRs <- dada(derepRs, err = errR, multithread = TRUE)

saveRDS(dadaFs, 'dadaFs.rds')
saveRDS(dadaRs, 'dadaRs.rds')

# Merge paired reads 
mergers <- mergePairs(dadaFs, derepFs, dadaRs, derepRs, verbose = TRUE,
                      minOverlap = 10)
saveRDS(mergers, 'mergers.rds')
head(mergers)

# If less than 75% of reads merge, also build sequence table with concatenated
# reads
getN <- function(x) sum(getUniques(x))

if (any((sapply(mergers, getN)/sapply(dadaFs, getN)) < 0.75)){
     print('Fewer than 75% of reads merged, generating concatenated table')
     concats <- mergePairs(dadaFs, derepFs, dadaRs, derepRs, verbose = TRUE,
                           justConcatenate=TRUE)
     saveRDS(concats, 'concats.rds')
}

# Construct Sequence Table ------------------------------------------------

seqtab <- makeSequenceTable(mergers)
dim(seqtab)
saveRDS(seqtab, "seqtab.rds")

# Inspect distribution of sequence lengths
table(nchar(getSequences(seqtab)))

if (exists('concats')){
     seqtab_concats <- makeSequenceTable(concats)
     dim(seqtab_concats)
     saveRDS(seqtab_concats, "seqtab_concats.rds")
     table(nchar(getSequences(seqtab_concats)))
}

# Remove Chimeras ---------------------------------------------------------

seqtab_nochim <- removeBimeraDenovo(seqtab, method="consensus", 
                                    multithread=TRUE, verbose=TRUE)
dim(seqtab_nochim)
sum(seqtab_nochim)/sum(seqtab)
saveRDS(seqtab_nochim, "seqtab_nochim.rds")

# Track reads through pipeline
track <- cbind(out, 
               sapply(dadaFs, getN), 
               sapply(dadaRs, getN), 
               sapply(mergers, getN), 
               rowSums(seqtab_nochim))
# If processing a single sample, remove the sapply calls: e.g. replace
# sapply(dadaFs, getN) with getN(dadaFs)
colnames(track) <- c("input", "filtered", "denoisedF", "denoisedR", "merged", 
                     "nonchim")
rownames(track) <- sample_names
head(track)

if (exists('concats')){
     seqtab_nochim_concats <- removeBimeraDenovo(seqtab_concats, 
                                                 method="consensus", 
                                                 multithread=TRUE, verbose=TRUE)
     dim(seqtab_nochim_concats)
     sum(seqtab_nochim_concats)/sum(seqtab_concats)
     saveRDS(seqtab_nochim_concats, "seqtab_nochim_concats.rds")
     
     # Track reads through pipeline
     track <- cbind(out, 
                    sapply(dadaFs, getN), 
                    sapply(dadaRs, getN), 
                    sapply(concats, getN), 
                    rowSums(seqtab_nochim_concats))
     # If processing a single sample, remove the sapply calls: e.g. replace
     # sapply(dadaFs, getN) with getN(dadaFs)
     colnames(track) <- c("input", "filtered", "denoisedF", "denoisedR", 
                          "concatenated", "nonchim")
     rownames(track) <- sample_names
     head(track)
}

# # Assign Taxonomy ---------------------------------------------------------
# 
# unite_ref <- '/data/davidlab/users/blp23/reference/UNITE/sh_general_release_dynamic_01.12.2017.fasta'
# 
# taxtab <- assignTaxonomy(seqtab_nochim, unite_ref, multithread = TRUE, 
#                          tryRC = TRUE)
# 
# # How many sequences are classified at different levels? (percent)
# colSums(!is.na(taxtab))/nrow(taxtab)
# saveRDS(taxtab, 'taxtab.rds')
# write.table(taxtab, file='taxtab.tsv', quote=FALSE, sep='\t') # Write to ascii
# 
# if (exists('concats')){
#      taxtab_concats <- assignTaxonomy(seqtab_nochim_concats, unite_ref, 
#                                       multithread = TRUE, tryRC = TRUE)
#      
#      colSums(!is.na(taxtab_concats))/nrow(taxtab_concats)
#      saveRDS(taxtab_concats, 'taxtab_concats.rds')
#      write.table(taxtab_concats, file='taxtab_concats.tsv', quote=FALSE, sep='\t')  
# }

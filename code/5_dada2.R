
# Applying dada2  pipeline to diet metabarcoding sequencing results

args <- commandArgs(trailingOnly=TRUE)
print(args)

setwd(args[2]) 
parent <- getwd()
indir <- args[3]
outdir <- args[4]

library(ShortRead); packageVersion('ShortRead') # for reading fastq .files
library(dplyr); packageVersion('dplyr') # For data wrangling
library(ggplot2); packageVersion('ggplot2') # For plots
library(magrittr); packageVersion('magrittr') # For pipe
library(tibble); packageVersion('tibble')
library(tidyverse); packageVersion('tidyverse')
library(dada2); packageVersion('dada2')

# Find filenames ----------------------------------------------------------

# Set directory for starting files: 
path <- file.path(parent, indir)
print(paste("Looking in ", path, " for read files"))
# Generate matched lists of forward and reverse filenames
fnFs <- sort(list.files(path, pattern = "R1.fastq.gz", full.names = TRUE))
fnRs <- sort(list.files(path, pattern = "R2.fastq.gz", full.names = TRUE))
print(paste("Found", length(fnFs), "forward read files"))
print(paste("Found", length(fnRs), "reverse read files"))

# Filter ------------------------------------------------------------------

# Put N-filtered files in filtN/ subdirectory
fnFs_filtN <- file.path(path, "filtN", basename(fnFs)) 
fnRs_filtN <- file.path(path, "filtN", basename(fnRs))

filt.out <- filterAndTrim(fnFs, fnFs_filtN, fnRs, fnRs_filtN, 
                          maxN = 0, 
                          maxEE = 2,
                          truncQ = 2,
                          minLen = 10, # trnL-P6 parameters (Taberlet)
                          maxLen = 143, # trnL-P6 parameters
                         # minLen = 56, # 12SV5 parameters (Schneider)
                         # maxLen = 132, # 12SV5 parameters
                          multithread = TRUE)

# Remove from our list files that now have 0 reads due to filtering
fnFs_filtN <- fnFs_filtN[file.exists(fnFs_filtN)]
fnRs_filtN <- fnRs_filtN[file.exists(fnRs_filtN)]

# Extract sample names, assuming filenames have format:
get_sample_name <- function(fnames){
       basenames <- 
              fnames %>% 
              basename() %>% # Remove path info 
              strsplit('_') %>% # Split at underscore (separates sample name from Illumina info)
              lapply('[[', 1) %>%  # Select name before split
              unlist() # Return to vector
       basenames
} 
sample_names <- get_sample_name(fnFs_filtN)
head(sample_names)

head(filt.out)

# Dereplication -----------------------------------------------------------

# Learn Error Rates
# Update path to output directory
path <- file.path(parent, outdir)
if (!dir.exists(path)){
     dir.create(path)
}
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
mergers <- mergePairs(dadaFs, derepFs, dadaRs, derepRs, verbose = TRUE)
saveRDS(mergers, 'mergers.rds')
head(mergers)

# If less than 75% of reads merge, also build sequence table with concatenated
# reads
getN <- function(x) sum(getUniques(x))

print('% of reads merged')
print(sapply(mergers, getN)/sapply(dadaFs, getN))

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
filt.out %>%
       as_tibble(rownames = "filename") %>%
       mutate(sample = get_sample_name(filename)) %>%
       select(sample, input = reads.in, filtered=reads.out) ->
       track

sapply(dadaFs, getN) %>%
       enframe(name="sample", value="denoised") ->
       denoised
track %<>% full_join(denoised, by=c("sample"))

sapply(mergers, getN) %>%
       enframe(name="sample", value="merged") ->
       merged
track %<>% full_join(merged, by=c("sample"))

rowSums(seqtab) %>%
       enframe(name="sample", value="tabled") ->
       tabled
track %<>% full_join(tabled, by=c("sample"))

rowSums(seqtab_nochim) %>%
       enframe(name="sample", value="nonchim") ->
       nonchim
track %<>% full_join(nonchim, by=c("sample"))

saveRDS(track, "track.rds")

if (exists('concats')){
     seqtab_nochim_concats <- removeBimeraDenovo(seqtab_concats, 
                                                 method="consensus", 
                                                 multithread=TRUE, verbose=TRUE)
     dim(seqtab_nochim_concats)
     sum(seqtab_nochim_concats)/sum(seqtab_concats)
     saveRDS(seqtab_nochim_concats, "seqtab_nochim_concats.rds")
}

# Count up reads at each step
parent<-args[1]
dirs<-c("0_raw_demux", "1_trimadapter","2_filter","3_trimprimer")
for (dir in seq_along(dirs)) { #this loops through each output folder and counts up how many reads are in each sample file
    folder<-file.path(parent,dirs[dir])
    fq<-countFastq(folder, pattern=".fastq.gz")
    colnames(fq)[1]<-dirs[dir]
    d<-fq[1]
    ifelse(dir==1,track.pipeline<-d,track.pipeline<-cbind(track.pipeline,d)) 
}
colnames(track.pipeline)<-c('raw', 
                           'adapter_trim', 
                           'primer_filter', 
                           'primer_trim')
sample<-gsub("_S.*$","",row.names(track.pipeline))
track.pipeline<-cbind(sample,track.pipeline)
row.names(track.pipeline)<-NULL
track.pipeline<-distinct(track.pipeline)
track.pipeline
write.csv(track.pipeline, file.path(parent,args[3],"track_pipeline.csv"), row.names=FALSE) #write csv with reads at preceding steps

track <- left_join(track.pipeline, track, by = c('sample', 
                                                 'primer_trim' = 'input'))
track.long <- pivot_longer(track, 
                           cols = -sample,
                           names_to = 'step', values_to = 'count')
track.long$step <- factor(track.long$step, 
                          levels = c('raw', 'adapter_trim', 'primer_filter',
                          'primer_trim', 'filtered', 'denoisedF','denoisedR',
                          'merged', 'nonchim'),
                          labels = c('Raw', 'Adapter\ntrimmed', 
                                     'Primer\nfiltered', 'Primer\ntrimmed',
                                     'Quality\nfiltered', 'Forward\ndenoised',
                                     'Reverse\ndenoised', 'Merged', 
                                     'Non-chimeric'))
# Add label for faceting Undetermined reads
track.long <- mutate(track.long,
                     label = ifelse(sample != 'Undetermined', 1, 0),
                     label = factor(label, labels = c('Undetermined', 'Samples')))
write.csv(track.long, file.path(parent,args[3],"track_long.csv"), row.names=FALSE) #write csv with reads at ALL steps ready to be plotted for QC

# Applying dada2  pipeline to diet metabarcoding sequencing results

args <- commandArgs(trailingOnly=TRUE)
print(args)

setwd(args[2]) 
parent <- getwd()
indir <- args[3]
outdir <- args[4]

library(dada2); packageVersion('dada2')
library(dplyr); packageVersion('dplyr') # For data wrangling
library(ggplot2); packageVersion('ggplot2') # For plots
library(magrittr); packageVersion('magrittr') # For pipe
library(tibble); packageVersion('tibble') # For enframe

# Find filenames ----------------------------------------------------------

# Set directory for starting files: 
path <- file.path(parent, indir)

# Generate list of filenames (could be all R1 or R2, but assume single-
# ended)
fns <- sort(list.files(path, pattern = ".fastq.gz", full.names = TRUE))

# Inspect read quality profiles -------------------------------------------

# Each sample individually
# Estimate plot width and height based on number of samples in each row or
# column
wh <- 
     length(fnFs) %>% 
     sqrt() %>% 
     ceiling()

p <- plotQualityProfile(fnFs)
ggsave(file.path(outdir, "quality_F.pdf"), plot = p,
       width = 7*wh, height = 7*wh, limitsize = FALSE)

p <- plotQualityProfile(fnRs)
ggsave(file.path(outdir, "quality_R.pdf"), plot = p,
       width = 7*wh, height = 7*wh, limitsize = FALSE)

# Overall quality of complete dataset (non-demultiplexed reads)
raw.fs <- 
     file.path(parent, '0_raw_all') %>%
     list.files(full.names = TRUE)

p <- plotQualityProfile(raw.fs[1]) # R1
ggsave(file.path(outdir, "quality_F_summary.png"), plot = p)

p <- plotQualityProfile(raw.fs[2]) # R2
ggsave(file.path(outdir, "quality_R_summary.png"), plot = p)

# Filter ------------------------------------------------------------------

# Put N-filtered files in filtN/ subdirectory
fns_filtN <- file.path(path, "filtN", basename(fns)) 

filt.out <- filterAndTrim(fns, fns_filtN,
                          maxN = 0, 
                          maxEE = 2,
                          truncQ = 20,
                          # minLen = 10, # trnL-P6 parameters (Taberlet)
                          # maxLen = 143, # trnL-P6 parameters
                          minLen = 56, # 12SV5 parameters (Schneider)
                          maxLen = 132, # 12SV5 parameters
                          multithread = TRUE)

# Remove from our list files that now have 0 reads due to filtering
fns_filtN <- fns_filtN[file.exists(fns_filtN)]

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
sample_names <- get_sample_name(fns_filtN)
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
err <- learnErrors(fns_filtN, multithread = TRUE, verbose=1)

# Visualize estimated error rates
p <- plotErrors(err, nominalQ = TRUE)
ggsave("dada_errors.png", plot = p)

# Dereplicate identical reads
dereps <- derepFastq(fns_filtN, verbose = TRUE)

# Name the derep-class objects by the sample names
names(dereps) <- sample_names

# Sample Inference --------------------------------------------------------

# Apply core sample inference algorithm to dereplicated sequences
# Save R objects throughout to allow return to data if follow-up needed

dadas <- dada(dereps, err = err, multithread = TRUE)

saveRDS(dadas, 'dadas.rds')

# Construct Sequence Table ------------------------------------------------

seqtab <- makeSequenceTable(dadas)
dim(seqtab)
saveRDS(seqtab, "seqtab.rds")

# Inspect distribution of sequence lengths
table(nchar(getSequences(seqtab)))

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

getN <- function(x) sum(getUniques(x))

sapply(dadas, getN) %>%
       enframe(name="sample", value="denoised") ->
       denoised
track %<>% full_join(denoised, by=c("sample"))

rowSums(seqtab) %>%
       enframe(name="sample", value="tabled") ->
       tabled
track %<>% full_join(tabled, by=c("sample"))

rowSums(seqtab_nochim) %>%
       enframe(name="sample", value="nonchim") ->
       nonchim
track %<>% full_join(nonchim, by=c("sample"))

saveRDS(track, "track.rds")
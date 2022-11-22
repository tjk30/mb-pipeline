library(ShortRead); packageVersion('ShortRead') # for reading fastq .files
library(dplyr); packageVersion('dplyr') # For data wrangling
library(ggplot2); packageVersion('ggplot2') # For plots
library(magrittr); packageVersion('magrittr') # For pipe
library(tibble); packageVersion('tibble')
library(tidyverse); packageVersion('tidyverse')
library(dada2)
# Count up reads at each step
args <- commandArgs(trailingOnly=TRUE)
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
write.csv(track.pipeline, file.path(parent,"4_dada2output","track_pipeline.csv"), row.names=FALSE) #write csv with reads at preceding steps
track<-readRDS(file.path(parent,"4_dada2output","track.rds"))
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
write.csv(track.long, file.path(parent,"4_dada2output","track_long.csv"), row.names=FALSE) #write csv with reads at ALL steps ready to be plotted for QC

# mb-pipeline

## Wet lab protocols

1. [DNA extraction](https://github.com/bpetrone/mb-pipeline/blob/master/protocols/1_dna_extraction.md)
2. [Primary PCR](https://github.com/bpetrone/mb-pipeline/blob/master/protocols/2_primary_pcr.md)
3. [Dilution](https://github.com/bpetrone/mb-pipeline/blob/master/protocols/3_dilution.md)
4. [Indexing PCR](https://github.com/bpetrone/mb-pipeline/blob/master/protocols/4_indexing_pcr.md)

## Computational pipeline

These scripts  produce, from Illumina MiniSeq raw sequencing data, a directory named DATE_results with the following structure:

```
DATE_results
 |
 +-- 0_raw
 |    
 +-- 1_trimadapter
 | 
 +-- 2_filterprimer
 |    
 +-- 3_trimprimer
 |    
 +-- 4_dada2
 ```
### Requirements

* A compute cluster with SLURM job submission
* A base [miniconda environment](https://docs.conda.io/en/latest/miniconda.html) with the following packages available: [bcl2fastq](https://anaconda.org/dranew/bcl2fastq), [cutadapt](https://cutadapt.readthedocs.io/en/stable/installation.html#installation-with-conda)
* An R installation with the following packages available: ```dada2```, ```dplyr```, ```ggplot2```, ```magrittr```, and ```tibble```

# mb-pipeline

## Wet lab protocols

1. DNA extraction
2. Primary PCR
3. Dilution
4. Indexing PCR

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

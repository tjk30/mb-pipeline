# mb-pipeline

## Wet lab protocols

1. [DNA extraction](https://github.com/bpetrone/mb-pipeline/blob/dfafcbb40f3d22f5a231bf532930bf5d98162f80/protocols/1_dna_extraction.md)
2. [Primary PCR](https://github.com/bpetrone/mb-pipeline/blob/dfafcbb40f3d22f5a231bf532930bf5d98162f80/protocols/2_primary_pcr.md)
3. [Dilution](https://github.com/bpetrone/mb-pipeline/blob/dfafcbb40f3d22f5a231bf532930bf5d98162f80/protocols/3_dilution.md)
4. [Indexing PCR](https://github.com/bpetrone/mb-pipeline/blob/dfafcbb40f3d22f5a231bf532930bf5d98162f80/protocols/4_indexing_pcr.md)

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

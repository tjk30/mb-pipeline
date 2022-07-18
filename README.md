# mb-pipeline

## Wet lab protocols

1. [DNA extraction](https://github.com/bpetrone/mb-pipeline/blob/master/protocols/1_dna_extraction.md) 
2. Primary PCR. One of:  
 2A. [trnL (plant)](https://github.com/bpetrone/mb-pipeline/blob/master/protocols/2A_primary_pcr_trnL.md)  
 2B. [12SV5 (vertebrate animals)](https://github.com/bpetrone/mb-pipeline/blob/master/protocols/2B_primary_pcr_12SV5.md) 
4. [Dilution](https://github.com/bpetrone/mb-pipeline/blob/master/protocols/3_dilution.md) 
5. [Indexing PCR](https://github.com/bpetrone/mb-pipeline/blob/master/protocols/4_indexing_pcr.md) 

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
* Have downloaded the metabarcoding Singularity container: https://gitlab.oit.duke.edu/lad-lab/metabarcoding/-/tree/main 

# Metabarcoding Pipeline Tutorial

1. [Demultiplexing](https://github.com/bpetrone/mb-pipeline/blob/master/code/1_demux-barcode.sh) 
2. [Trim adapters](https://github.com/bpetrone/mb-pipeline/blob/master/code/2_trim-adapters.sh)
3. [Filter primers](https://github.com/bpetrone/mb-pipeline/blob/master/code/3_filter-primers.sh)
4. [Trim primers](https://github.com/bpetrone/mb-pipeline/blob/master/code/4_trim-primers.sh)
5. Data analysis object generation and QC 
    5A. [Submission script](https://github.com/bpetrone/mb-pipeline/blob/master/code/5_dada2.sh) 
    5B. [Rscript](https://github.com/bpetrone/mb-pipeline/blob/master/code/5_dada2.R) 
    5C. [Write Rout file](https://github.com/bpetrone/mb-pipeline/blob/master/code/Rscript-echo.R) 
    
## Setup

Clone this repo to the computing cluster:
```
#navigate to where you want to store the scripts
git clone https://github.com/bpetrone/mb-pipeline.git
```

After getting your data off of the sequencer, upload it to the computing cluster. For example, here is how you would upload to the DCC:

```
#"IlluminaRunFolder will look something like "211019_MN00462_0194_A000H3L2M7"
scp -r /path/to/your/<IlluminaRunFolder> <your-netid>@dcc-login.oit.duke.edu:/path/to/DCC/folder
```

Next, upload your samplesheet.csv file and make sure that you have the following file structure:
```
/seqdata #name this whatever you want
  -########_samplesheet.csv 
  -211019_MN00462_0194_A000H3L2M7 #note that this and sample sheet should be in the SAME folder
```
See "Troubleshooting" for more information regarding sample sheet structure if you aren't sure what an Illumina sample sheet should look like. 

You will also need to download the metabarcoding container file to the computing cluster you're using with the following command:
```
#navigate to whatever directory you want to store the container in
curl -O https://research-singularity-registry.oit.duke.edu/lad-lab/metabarcoding.sif
```
This is a Singularity (aka computing cluster compatible) container that has all of the packages you need for analysis pre-installed, so no other package installations are needed!

See the below instructions for how to run each step of the pipeline. There is also a [template file](https://github.com/bpetrone/mb-pipeline/blob/master/code/script-writer.Rmd) that will write each submission script for you if you just want to copy/paste the correct commands.

## Step 1: bcl2fastq and demultiplexing

The first step of this pipeline is to convert the raw .bcl files from the sequencer into individual .fastq files for each sample. You will need:
- The path to your Illumina run folder 
- Sample sheet name
- Path to where you stored the metabarcoding.sif container file
- The diet metabarcoding run type (trnL or 12SV5)

```
#navigate to the mb-pipeline folder on your computing cluster
sbatch --mail-user=youremail@duke.edu 1_demux-barcode.sh /path/to/metabarcoding.sif path/to/miniseq-dir XXXXXXXX_sample-sheet.csv <trnL>OR<12SV5>
```
This can take about an hour to run with 192 samples. 

After this script has finished, you should see the following file structure:
```
/seqdata 
  -########_samplesheet.csv 
  -miniseq-dir
    -XXXXXXXX_results
      -0_reference
        -primers.txt
      -1_raw_demux
        #all of your demultiplexed .fastq files will be here
      -1_raw_all
        Undetermined_S0_L001_R1_001.fastq
        Undetermined_S0_L001_R2_001.fastq # these files contain everything, included PhiX and all reads that didn't match to the barcodes you input
```
Check the .out and .err files to make sure that everything went smoothly
### Troubleshooting
If demultiplexing failed, here are the most common issues:
1. Incorrect file structure: is your sample sheet located in the same folder as your Illumina run folder?
2. Incorrect sample sheet input: Does the input sample sheet name match what you have in the folder?
3. Incorrect sample sheet format: bcl2fastq requires a very specific sample sheet format. If there is an empty row or hidden character where there shouldn't be, then it will give an error. Sometimes, it's necessary to copy and paste the sample sheet from a run that has worked in the past (or, use [this sample](https://github.com/bpetrone/mb-pipeline/blob/master/code/samplesheet-template.csv)) and then re-paste in the barcodes you used. 
4. Not using exactly "trnL" or "12SV5" as the run type argument. This input is case sensitive, make sure you use exactly "trnL" or "12SV5" as the last argument. 
5. Other file path issues: double check that all of the file paths are correct and that there aren't any missing back slashes. Did you correctly type the miniseq-dir path? 
6. Trying to submit command from outside /mb-pipline/code folder. If you aren't submitting the sbatch command from inside the mb-pipeline folder, you will need to encode the path to the script in your sbatch command. I.e.;
```
sbatch --mail-user=youremail@duke.edu /PATH/TO/1_demux-barcode.sh /path/to/metabarcoding.sif path/to/miniseq-dir XXXXXXXX_sample-sheet.csv <trnL>OR<12SV5>
```


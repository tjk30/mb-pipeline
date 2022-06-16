Instructions for running pipeline scripts on HARDAC:

## Copy pipeline scripts and raw MiniSeq data to HARDAC
1. Clone this directory to your local machine.
2. Update the email line in each script (the last line in the group of `#SBATCH` header lines) to your email address, to be notified when a job completes or fails.
3. Transfer to a scripts folder in your home directory on HARDAC (`~/scripts`).
4. Make a subdirectory for storing script error and output files (`~/scripts/reports`).
5. Copy the full MiniSeq run directory (the one named DATE_MN00462_RUN_FLOWCELL) to your folder in HARDAC's `data` directory (`/data/davidlab/users/NETID/`). I usually make a readable descriptor of the run as a parent directory and place the run inside this folder, for example `/data/davidlab/users/blp23/seqdata/20201128_ONR_trnL/` and transfer the data there.
6. Copy the sample sheet mapping samples to their forward and reverse barcode sequences to HARDAC.  The demultiplexing script expects this to be in the same parent directory as the raw MiniSeq data folder, *e.g.*

```
20201128_results
 |
 +-- 20201128_sample_sheet.csv
 |    
 +-- 201128_MN00462_0146_A000H37W7H
     | 
     +-- Raw data
     |
     +-- ...
 ```

## Run the pipeline scripts in order

In the future, we could connect these to run all in a single command (BP has old email from MV on how to string scripts together with SLURM).  In practice, there are hiccups often enough that I like the scripts separated, which prompts me to inspect the output as I go and revisit a particular step if needed.

All scripts are submitted on the commandline with the following syntax:
`sbatch SCRIPTNAME.sh argument1 argument2 ...`, where the arguments are customized to each script.

In general, the first argument will be the parent directory of the data the script is working on.  A handy way to reference this directory is by saving it to a shell variable, which can be passed to the script rather than typing out the full path.  To do so, go into the directory that you want to set as a variable, and do

```
dir=$(pwd)
```

This assigns the output of the print working directory (`pwd`) command to the variable name `dir`.  You can now reference this value by typing `$dir`.  This is helpful not only as an argument but for quickly navigating back and forth between the scripts directory, where the `sbatch` commands are submitted, and the data directory where the outputs are saved.

### Step 1: Demultiplex the raw reads

Software: bcl2fastq2 v2.20.0.422 (Illumina), running inside a Miniconda3 environment
Script: 1_demux-barcode.sh

* Set the `dir` variable to the MiniSeq raw data directory (201128_MN00462_0146_A000H37W7H in the example above)
* Make sure the sample sheet is in the same parent directory as the raw data folder, and note its name
* Submit the script using `sbatch 1_demux-barcode.sh $dir SAMPLE_SHEET_NAME.csv`, substituting the name of your sample sheet.  The script knows to look for the sample sheet one directory above the raw data, so you only need the name, not the full path.

This script will do the following:
* Create a directory structure for pipeline results of the form
```
DATE_results
 |
 +-- 0_raw_all
 |
 +-- 0_raw_demux
 |    
 ...
 ```
* Convert all basecall files to FASTQ read files, and save them either in one bulk file of forward and reverse reads (`0_raw_all`) or demultiplexed by barcode (`0_raw_demux`). 


### Step 2: Trim read-through into Illumina adapters

Software:

### Step 3: Filter for only reads that have the amplification primers

Software: 

### Step 4: Trim off the amplification primers

### Step 5: Run DADA2

Instructions for running pipeline scripts on HARDAC:

## Copy pipeline scripts and raw MiniSeq data to HARDAC
1. Clone this directory to your local machine.
2. Transfer to a scripts folder in your home directory on HARDAC (`~/scripts`).
3. Make a subdirectory for storing script error and output files (`~/scripts/reports`).
4. Copy the full MiniSeq run directory (the one named DATE_MN00462_RUN_FLOWCELL) to your folder in HARDAC's `data` directory (`/data/davidlab/users/NETID/`). I usually make a readable descriptor of the run as a parent directory and place the run inside this folder, for example `/data/davidlab/users/blp23/seqdata/20201128_ONR_trnL/` and transfer the data there.
5. Copy the sample sheet mapping samples to their forward and reverse barcode sequences to HARDAC.  The demultiplexing script expects this to be in the same parent directory as the raw MiniSeq data folder, *e.g.*

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

In the future, we could connect these to run all in a single command (BP has old email from MV on how to string scripts together with SLURM).  In practice though I find there are hiccups often enough that I like to inspect the output as I go and can revisit a particular step if needed.

### Step 1: Demultiplex the raw reads

### Step 2: Trim read-through into Illumina adapters

### Step 3: Filter for only reads that have the amplification primers

### Step 4: Trim off the amplification primers

### Step 5: Run DADA2

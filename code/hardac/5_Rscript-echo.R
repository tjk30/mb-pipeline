# Rscript-echo.R

# Using a combination of source() and sink(), get Rscript to produce an .Rout file like that
# produced by R CMD BATCH. 

# Command-line usage: Rscript Rscript-echo.R [Primary script name] [Primary script args]
# Remember to adjust args indices of receiving script accordingly!

args <- commandArgs(TRUE)
srcfile <- args[1]

dir.create(file.path(args[2], args[4]))
outfile <- file.path(args[2], args[4], paste0(make.names(date()), '.Rout'))
# args <- args[-1] # This trims off the first entry of args, but I'm not sure why

sink(outfile, split=TRUE)
source(srcfile, echo=TRUE)

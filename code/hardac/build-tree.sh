module load raxml

# Adapted from https://github.com/benjjneb/dada2/issues/88#issuecomment-285488073

# -s sequence filename
# -n output filename
# -m substitution model
# -f best tree and bootstrap
# -p random number seed
# -x random seed for rapid bootstrapping
# -N number of bootstrap iterations
# 
raxmlHPC -s -n -m "GTRGAMMAIX" -f "a"

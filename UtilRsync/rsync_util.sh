#!/bin/bash
# courtesy of: http://redsymbol.net/articles/unofficial-bash-strict-mode/
# (helps with debugging)
# set -e: immediately exit if we find a non zero
# set -u: undefined references cause errors
# set -o: single error causes full pipeline failure.
set -euo pipefail
IFS=$'\n\t'
# datestring, used in many different places...
dateStr=`date +%Y-%m-%d:%H:%M:%S`

# Description:

# Arguments:
#### Arg 1: input directory (either abs or relative)
#### Arg 2: output directory (either abs or relative)
#### Arg 3: additional flags 

# Returns:

# note: following line works in one directory above Data"
#  rsync.exe -Rv ./Data/rationale/N2/cache_0_binding/binding.pkl ../../../Dropbox/scratch/

input="${1?Must specify input location}"
output="${2?Must specify output location}"
flags="${@:3}"
# go to the output directory, get the absiolute 
mkdir -p "$output"
cd "$output" > /dev/nulll
output_abs=$(pwd)
cd - > /dev/null
# go back to the input directory 
cd "$input"
set -x 
rsync -zarv \
     --include="*/" \
     "${@:3}" \
     --include="*.txt" \
     --include="*.pxp" \
     --exclude="*.png" \
     --exclude="*.jpeg" \
     --exclude="*.pkl" \
     --prune-empty-dirs \
     ./ "${output_abs}"

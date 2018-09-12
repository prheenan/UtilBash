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

# Description: Used to generate figures


function generate_dir(){
    # Args:
    #       $1: input directory, run *all* things like '*main*.py' from here.
    local in_dir="$1"
    local args="${@:2}"
    local current=$(pwd)
    cd $in_dir
    local files=$( find . -name "*main*.py" )
    for f in $files
        do
            local dir_tmp=$(dirname "$f")
            local to_run=$(basename "$f")
            cd "$dir_tmp"
            local dir_abs=$(pwd)
            local base_cmd="figure_util.sh:: Running $to_run in $dir_abs"
            if [ ${#args} -eq 0 ]; then
                echo "$base_cmd without args"
                python "$to_run"
            else
               echo "$base_cmd with [$args]"
               python "$to_run" "$args"
            fi
            cd -
        done
    cd $current
}

function _copy_figures(){
    # see: copy_dir
    local in_dir="$1"
    local out_dir="$2"
    local name="$3"
    find $in_dir -type f -name "$name" -exec cp {} "$out_dir" \;
}

function copy_dir(){
    # Args:
    #       $1: input directory, copy all files like *Figure* from here
    #       $2: output directory, where to copy the figures
    local in_dir="$1"
    local out_dir="$2"
    mkdir -p "$out_dir"
    _copy_figures "$in_dir" "$out_dir" "*Figure*"
}

function make_figures(){
    # Args:
    #       $1: skip_generation: if 1, then we only copy and do not regenerate
    #       $2: input directory, search for *main*.py here. See  generate_dir
    #       $3: output directory, see copy-dir
    local skip_generation="$1"
    local in_dir="$2"
    local out_dir="$3"
    # make sure the output exists.
    mkdir -p "$out_dir"
    if [ "$skip_generation" -eq 0 ]; then
        # delete the old files
        echo "figure_util.sh:: Removing all figure files from $out_dir"
        rm -f "${out_dir}"*"Figure"*
        # make new ones
        echo "Generating $in_dir"
        generate_dir "$in_dir"
        echo ""
    else
        echo "figure_util.sh:: skipping generation for $in_dir, just copying."
    fi
    # copy the resulting stuff. 
    copy_dir "${@:2}"
}
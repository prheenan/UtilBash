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

# Description: Used (in linux / OSX / system with ImageMagick's convert)
# to resize the tiff and pdfs so they are the appropariate width (3.25 or 6.75
# inches). Assumes the data is in the Scratch/ directory under perknas2/4Patrick

function resize_single(){
    # Arguments:
    #### Arg 1: input file
    #### Arg 2: desired width in inches. Assuming DPI same in x an y
    local in_file="${1}"
    local new_width_inches="${2}"
    if [[ "$in_file" == *tiff ]]; then
        local dpi=$( identify -format "%x" "$in_file" )
        else
        local dpi=1200
    fi
    echo "Using dpi=$dpi for $in_file"
    local new_width=$( bc <<< "$new_width_inches * $dpi" )
    local old_width=$( identify -format "%w" "$in_file" )
    local old_height=$( identify -format "%h" "$in_file" )
    local new_height=$( python2 -c "from __future__ import division; from numpy import round; print int(round($new_width * $old_height/$old_width))")
    # print out some simple information
    local geometry_str="${new_width}x${new_height}"
    echo "Old: $old_width x $old_height. New: $geometry_str (dpi: $dpi)"
    # convert and overwrite it. See :
    # imagemagick.org/script/command-line-options.php#resize
    # and
    # https://www.imagemagick.org/script/command-line-processing.php#geometry
    convert -verbose\
	    -density $dpi \
	    $in_file \
	    -quality 100 \
	    -flatten\
	    -sharpen 0x1\
	    -resize $geometry_str \
	    -density $dpi \
	    "${in_file}" 
}

function resize_with_ext(){
    local input_dir="$1"
    local figure_id="$2"
    local figure_ext="$3"
    local figure_size="$4"
    local tmp_name="Figure${figure_id}*.${figure_ext}"
    files=$( find "$input_dir" -name $tmp_name)
    echo "Found [$files] from $tmp_name"
    file_tmp=$( echo "$files"  | tail -n 1)
    echo "Resizing $file_tmp"
    resize_single $file_tmp "$figure_size"

}

function resize_files(){
    local input_dir="$1"
    local new_width_inches="$2"
    declare -a file_list=("${!3}")
    echo "File list is ${file_list[@]}"
    for i in "${file_list[@]}"
    do
        echo "Working with $i"
        # resize everything...
        resize_with_ext "$input_dir" "$i" "jpeg" "$new_width_inches"
        resize_with_ext "$input_dir" "$i" "tiff" "$new_width_inches"
        resize_with_ext "$input_dir" "$i" "pdf" "$new_width_inches"
    done		       
}



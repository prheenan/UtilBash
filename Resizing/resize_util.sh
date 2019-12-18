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
# inches). 

# note: assumes that ImageMagic convert is on the path. It can be downloaded
# at https://www.imagemagick.org/script/download.php
# note that during the install, you *should* install the 'legacy' libraries

# I then put it on the path via
# export PATH="/c/Program Files/ImageMagick-7.0.8-Q16/:$PATH"

def_dpi=600
def_quality=80

function resize_single(){
    # Arguments:
    #### Arg 1: input file
    #### Arg 2: desired width in inches. Assuming DPI same in x an y
    local in_file="${1}"
    local new_width_inches="${2}"
    local dpi="${3:-$def_dpi}"
    local quality="${4:-$def_quality}"
    echo "Using dpi=$dpi for $in_file"
    local new_width=$( bc <<< "$new_width_inches * $dpi" )
    local old_width=$( identify -format "%w" "$in_file" )
    local old_height=$( identify -format "%h" "$in_file" )
    # get the new height
    local height_str="from __future__ import division;"
    local height_str="$height_str from numpy import round;"
    local height_str="$height_str print(int(round($new_width * $old_height/$old_width)))"  
    local new_height=$( python -c "$height_str")
    # determine if we are within 1 pixel. If so, we don't resize
    local skip_str="print( (abs($old_height - $new_height) <= 1) and "
    local skip_str="$skip_str (abs($old_width - $new_width) <= 1))"
	echo "resize_util.sh:: running with $skip_str"
    local skip=$( python -c "$skip_str")
    # print out some simple information
    local geometry_str="${new_width}x${new_height}"
    echo "Old: $old_width x $old_height. New: $geometry_str (dpi: $dpi)"
    if [ "$skip" = "True" ]; then
        echo "Old and new geometry within 1 pixel; skipping resiziing"
        return
    fi
    # convert and overwrite it. See :
    # imagemagick.org/script/command-line-options.php#resize
    # and
    # https://www.imagemagick.org/script/command-line-processing.php#geometry
    convert -verbose\
	    -density $dpi \
	    $in_file \
	    -quality "$quality" \
	    -flatten\
	    -sharpen 0.05\
	    -resize $geometry_str \
	    -density $dpi \
	    "${in_file}" 
}

function resize_with_ext(){
    local input_dir="$1"
    local figure_id="$2"
    local figure_ext="$3"
    local figure_size="$4"
    local dpi="${5:-$def_dpi}"
    local tmp_name="Figure*${figure_id}*.${figure_ext}"
    files=$( find "$input_dir" -name $tmp_name)
	local n_found=$( echo "$files" | wc -l)
	local file_str_len=${#files} 
    if [ $n_found = "0" ] || [ $file_str_len = "0" ]; then 
        echo "Found nothing from $tmp_name, skipping"
        return 
    elif [ $n_found = "1" ]; then 
        echo "Found [$files] from $tmp_name"
	else 
		echo "For $tmp_name, found more than one file ($files). Skipping"
		return 
    fi
    file_tmp=$( echo "$files"  | tail -n 1)
    echo "Resizing $file_tmp"
    resize_single $file_tmp "$figure_size" "$dpi"
}

function resize_files(){
    local input_dir="$1"
    local new_width_inches="$2"
    declare -a file_list=("${!3}")
    local dpi="${4:-$def_dpi}"
    echo "resize_util:: File list is ${file_list[@]}"
    for i in "${file_list[@]}"
    do
        echo "Working with $i ($new_width_inches, $dpi)"
        # resize everything...
        resize_with_ext "$input_dir" "$i" "jpeg" "$new_width_inches" $dpi
        resize_with_ext "$input_dir" "$i" "tiff" "$new_width_inches" $dpi
        resize_with_ext "$input_dir" "$i" "pdf" "$new_width_inches" $dpi
        resize_with_ext "$input_dir" "$i" "png" "$new_width_inches" $dpi
    done		       
}



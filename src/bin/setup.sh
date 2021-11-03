#!/bin/bash
dir_path=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

# library files
for file in $(find $dir_path/../../lib/ -name "*.sh"); do
    source $file
done

# script files
for file in $(find $dir_path/../ -name "yt*.sh"); do
    source $file
done
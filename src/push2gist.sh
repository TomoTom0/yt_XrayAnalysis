#!/bin/bash

# use gist installed from gem
# ---- NOT gist on python-gist ----

# ---------------------
##     obtain options
# ---------------------


dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd) # noqa
source ${dir_path}/../lib/obtain_options.sh

#echo $dir_path

function __usage() {
    echo "Usage: $0 [-f,--force] [--dry] [-h,--help]" 1>&2
    return 0
}

# arguments settings
declare -A flagsAll=(
    ["h"]="help"
    ["--help"]="help"
    ["--dry"]="dry"
    ["f"]="force"
    ["--force"]="force"
)
declare -A flagsArgDict=()

# arguments variables
declare -i argc=0
declare -A kwargs=()
declare -A flagsIn=()

declare -a allArgs=($@)

__obtain_options allArgs flagsAll flagsArgDict argc kwargs flagsIn
#flagsIn[force]=111
if [[ " ${!flagsIn[@]} " =~ " help " ]]; then
    __usage
    exit 1
fi

# ----------------------------------------- #

# ---------------------
##         main
# ---------------------

# dry check
if [[ -n ${flagsIn[dry]} ]]; then
    echo "  ---- This is dry mode ----  "
fi

generated_files=$(find "${dir_path}/../tmp/" -maxdepth 1 -name "*.sh" -printf "%f\n" | sort)
## read gist list
config_data=($(gist -l 2>/dev/null | awk "{print \$1 \"___\"  \$2}"))
declare -A gist_dict=()
## generate dict
for line in ${config_data[@]}; do
    val=${line%%___*}
    key=${line##*___}
    if [[ -z $key || -z $val ]]; then 
        continue
    elif [[ -n ${gist_dict[$key]} ]];then
        echo "delete $val for $key"
        if [[ -z ${flagsIn[dry]} ]]; then
            gist --delete $val  2>/dev/null 
        fi
    else
        gist_dict[$key]=$val
    fi
done
## upload files to gist
declare -A valid_gist_dict=()
for file in ${generated_files[@]}; do
    diff_tmp=$(diff ${dir_path}/../tmp/$file ${dir_path}/../gist/$file 2>/dev/null || echo $?)
    if [[ -z ${diff_tmp} && -z ${flagsIn[force]} ]]; then
        ### no change -> skip
        echo "$file is skipped becuase of not changing"
        valid_gist_dict[$file]=${gist_dict[$file]}
        continue
    elif [[ -z ${diff_tmp} && -n ${flagsIn[force]} ]]; then
        echo "$file is NOT skipped becuase --force flag is true"
    fi
    gist_url=${gist_dict[$file]}
    if [[ "x${gist_url[0]}" != x ]]; then
        echo "${gist_url[0]} for $file"
        if [[ -z ${flagsIn[dry]} ]]; then
            ### update gist
            tmp_url=$(gist "${dir_path}/../tmp/$file" -u $gist_url  2>/dev/null )
            valid_gist_dict[$file]=$tmp_url
        fi
    else
        echo "hash not found for $file"
        if [[ -z "${flagsIn[dry]}" ]]; then
            ### create gist
            tmp_url=$(gist --no-private "${dir_path}/../tmp/$file" 2>/dev/null )
            valid_gist_dict[$file]=$tmp_url
        fi
    fi
done

if [[ -z "${flagsIn[dry]}" ]]; then
    ## write to config.dat
    config_path=config.dat
    :>$config_path
    for file in $(printf "%s\n" ${!valid_gist_dict[@]} | sort); do
        echo "$file ${valid_gist_dict[$file]##*\/}" >> $config_path
    done

    ## cp generated files to ../gist/
    rm ${dir_path}/../gist -rf && mkdir ${dir_path}/../gist -p &&
        cp ${dir_path}/../tmp/*.sh ${dir_path}/../gist/ -f
fi
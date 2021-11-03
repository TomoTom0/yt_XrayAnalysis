#!/bin/bash

# ---------------------
##     obtain options
# ---------------------

source ../lib/obtain_options.sh

function __usage() {
    echo "Usage: $0 [-f,--force] [--dry] [-h,--help]" 1>&2
    cat << EOF
------
This script is combined with restruct.py and push2gist.sh
------
EOF
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

if [[ " ${!flagsIn[@]} " =~ " help " ]]; then
    __usage
    return 0
fi

# ----------------------------------------- #

# ---------------------
##         main
# ---------------------

if [[ -n ${flagsIn[dry]} ]]; then
    python3 restruct.py
fi

bash push2gist.sh $@


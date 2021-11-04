#!/bin/bash

function __usage() {
    echo "Usage: ${FUNCNAME[1]} allArgs flagsAll flagsArgDict argc kwargs flagsIn" 1>&2
    cat <<EOF
-----
# argument settings
declare -A flagsAll=(
    ["h"]="help"
    ["--help"]="help"
    ["--dry"]="dry"
    ["f"]="force"
    ["--force"]="force"
    ["--file"]="file"
)
declare -A flagsArgDict=(
    ["file"]="name"
)
# variables for results
declare -i argc=0
declare -A kwargs=()
declare -A flagsIn=()

declare -a allArgs=(\$@)

${FUNCNAME[1]} allArgs flagsAll flagsArgDict argc kwargs flagsIn
EOF
    return 0
}

function __obtain_options() {

    if (($# < 6)); then
        echo "${FUNCNAME[0]}: the number of arguments is less than 6"
        echo "${FUNCNAME[0]}: please add required arguments: "
        echo "${FUNCNAME[0]}: allArgs flagsAll flagsArgDict argc kwargs flagsIn"
        return 0
    fi
    # all arguments
    declare -n __allArgs="$1"

    # argument settings
    declare -n __flagsAll="$2"
    declare -n __flagsArgDict="$3"

    # variables for results
    declare -n __argc="$4"
    declare -n __kwargs="$5"
    declare -n __flagsIn="$6"

    # obtain options and arguments
    declare -i shift_count=0
    while ((shift_count < ${#__allArgs[@]})); do
        arg="${__allArgs[$shift_count]}"
        case $arg in
        -*)
            # long flag -> short flag
            for flag in $(printf "%s\n" ${!__flagsAll[@]} | sort); do
                declare -i tmp_flagCount=0
                flagArg=false
                flagIsLong=false
                flag_id=""
                # long flag -> complete match
                if [[ "${#flag}" -gt 1 && "$arg" == "$flag" ]]; then
                    flag_id=${__flagsAll[$flag]}
                    __flagsIn[$flag_id]="$shift_count"
                    flagIsLong=true
                    ((tmp_flagCount++))
                # short flag -> partial match
                elif [[ "${#flag}" -eq 1 && ! "x$arg" =~ "^x--" && "$arg" =~ "$flag" ]]; then
                    flag_id=${flagsAll[$flag]}
                    __flagsIn[$flag_id]="$shift_count"
                    ((tmp_flagCount++))
                fi
                # check whether arguments are accompanied or not
                if [[ -n "$flag_id" && $tmp_flagCount -eq 1 && " ${!flagsArgDict[@]} " =~ " $flag_id " ]]; then
                    flagArg=true
                    for argName in ${__flagsArgDict[${flag_id}]}; do
                        ((shift_count++))
                        tmp_arg=${__allArgs[$shift_count]}
                        # arguments OPTION can start with "-" or not
                        if [[ "x${tmp_arg}" =~ "^x-" ]]; then
                            ((shift_count--))
                            break
                        fi
                        __kwargs["${flag_id}__${argName}"]="$tmp_arg"
                    done
                fi
                if [[ "x$flagIsLong" == "xtrue" ||"x$flagArg" == "xtrue" ]]; then
                    break
                fi
            done
            # UNKNOWN OPTION
            #if ((tmp_flagCount == 0)); then
            #    __kwargs[UNKNOWN__FLAG]="${__kwargs[UNKNOWN__FLAG]} $arg"
            #fi
            ;;
        *)
            __kwargs[$argc]="$arg"
            ((argc++))
            ;;
        esac
        ((shift_count++))
    done

    return 0
}

#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd) # noqa
source ${dir_path}/../../lib/obtain_options.sh


alias yt_nicerXti__a="_NicerXti_a_products"
function _NicerXti_a_products() {
    ## before ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute all the processes
    Please check help of yt_nicerXti_1 ... yt_nicerXti_5
    Inputted options are succeeded to the functions properly.


Options
-h,--help
    show this message

....

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
    )
    declare -A flagsArgDict=(
    )

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

    # ---------------------
    ##         main
    # ---------------------
    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Nicer_D=${My_Nicer_D:=$(pwd)} 
    else 
        declare -g My_Nicer_D=${My_Nicer_D:=$(pwd)} 
    fi
    yt_nicerXti_1 $@ &&
        yt_nicerXti_2 $@ &&
        yt_nicerXti_3 $@ &&
        yt_nicerXti_4 $@ &&
        yt_nicerXti_5 $@
    return 0
}
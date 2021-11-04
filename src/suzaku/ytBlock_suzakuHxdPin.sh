#!/bin/bash

alias yt_suzakuHxd__a="_SuzakuHxd_a_all"
function _SuzakuHxd_a_all() {
    ## all
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute all processes
    Please check help of yt_suzakuHxd_1 ... yt_suzakuHxd_7
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
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    yt_suzakuHxd_1 $@ &&
        yt_suzakuHxd_2 $@ &&
        yt_suzakuHxd_3 $@ &&
        yt_suzakuHxd_4 $@ &&
        yt_suzakuHxd_5 $@ &&
        yt_suzakuHxd_6 $@ &&
        yt_suzakuHxd_7 $@

    return 0
}

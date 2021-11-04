#!/bin/bash

alias yt_suzakuXis__a="_SuzakuXis_a_ds9"
function _SuzakuXis_a_beforeDs9() {
    ## ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process with ds9
    Please check help of yt_suzakuXis_1
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
    yt_suzakuXis_1 $@
    return 0
}

alias yt_suzakuXis__b="_SuzakuXis_b_afterDs9"
function _SuzakuXis_b_afterDs9() {
    ## after ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process with ds9
    Please check help of yt_suzakuXis_2 ... yt_suzakuXis_7
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
    yt_suzakuXis_2 $@ &&
        yt_suzakuXis_3 $@ &&
        yt_suzakuXis_4 $@ &&
        yt_suzakuXis_5 $@ &&
        yt_suzakuXis_6 $@ &&
        yt_suzakuXis_7 $@
    return 0
}

#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd) # noqa
source ${dir_path}/../../lib/obtain_options.sh


alias yt_nustar__a="_Nustar_a_beforeDs9"
function _Nustar_a_beforeDs9() {
    ## before ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process before ds9
    Please check help of yt_nustar_1
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
    declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)}
    yt_nustar_1 $@
    return 0
}

alias yt_nustar__b="_Nustar_b_ds9"
function _Nustar_b_ds9() {
    ## ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process with ds9
    Please check help of yt_nustar_2
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
    declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)}
    yt_nustar_2 $@
    return 0
}

alias yt_nustar__c="_Nustar_c_afterDs9"
function _Nustar_c_afterDs9() {
    ## after ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process after ds9
    Please check help of yt_nustar_3 ... yt_nustar_7
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
    declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)}
    yt_nustar_3 $@ &&
        yt_nustar_4 $@ &&
        yt_nustar_5 $@ &&
        yt_nustar_6 $@ &&
        yt_nustar_7 $@
    return 0
}

#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd) # noqa
source ${dir_path}/../../lib/obtain_options.sh


alias yt_suzakuHxdGso__a="_SuzakuHxdGso_a_all"
function _SuzakuHxdGso_a_all() {
    ## all
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute all processes
    Please check help of yt_suzakuHxdGso_1 ... yt_suzakuHxdGso_5
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
    yt_suzakuHxdGso_1 $@ &&
        yt_suzakuHxdGso_2 $@ &&
        yt_suzakuHxdGso_3 $@ &&
        yt_suzakuHxdGso_4 $@ &&
        yt_suzakuHxdGso_5 $@ 

    return 0
}

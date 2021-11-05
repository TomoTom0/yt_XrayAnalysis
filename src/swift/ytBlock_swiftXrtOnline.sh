#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd) # noqa
source ${dir_path}/../../lib/obtain_options.sh


alias yt_swiftXrtBuild__a="_SwiftXrt_a_all"
function _SwiftXrtBuild_a_all() {
    ## all processes for swift xrt spectrum built online on 1SXPS
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute all processes for swift xrt spectrum built online on 1SXPS
    Please check help of yt_swiftXrtBuild_1 ... yt_swiftXrtBuild_3
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
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
    yt_swiftXrtBuild_1 $@ &&
    yt_swiftXrtBuild_1 $@ &&
    yt_swiftXrtBuild_3 $@
    return 0
}

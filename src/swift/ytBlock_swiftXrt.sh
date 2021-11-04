#!/bin/bash

alias yt_swiftXrt__a="_SwiftXrt_a_beforeDs9"
function _SwiftXrt_a_beforeDs9() {
    ## before ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process before ds9
    Please check help of yt_swiftXrt_1
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
    yt_swiftXrt_1 $@
    return 0
}

alias yt_swiftXrt__b="_SwiftXrt_b_ds9"
function _SwiftXrt_b_ds9() {
    ## ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process with ds9
    Please check help of yt_swiftXrt_2
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
    yt_swiftXrt_2 $@
    return 0
}

alias yt_swiftXrt__c="_SwiftXrt_c_afterDs9"
function _SwiftXrt_c_afterDs9() {
    ## after ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process after ds9
    Please check help of yt_swiftXrt_3 ... yt_swiftXrt_7
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
    yt_swiftXrt_3 $@ &&
        yt_swiftXrt_4 $@ &&
        yt_swiftXrt_5 $@ &&
        yt_swiftXrt_6 $@ &&
        yt_swiftXrt_7 $@
    return 0
}

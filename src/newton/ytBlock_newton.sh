#!/bin/bash

alias yt_newton__a="_Newton_a_beforeDs9"
function _Newton_a_beforeDs9() {
    ## before ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process before ds9
    Please check help of yt_newton_1 ... yt_newton_2
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
        ["--ignore"]="ignore"
        ["--clean"]="clean"
    )
    declare -A flagsArgDict=(
        ["ignore"]="cameras"
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

    # ----------------------------------------- #

    # ---------------------
    ##         main
    # ---------------------
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    yt_newton_1 $@ &&
        yt_newton_2 $@
    return 0
}

alias yt_newton__b="_Newton_b_ds9"
function _Newton_b_ds9() {
    ## ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process with ds9
    Please check help of yt_newton_3
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
        ["--ignore"]="ignore"
        ["--clean"]="clean"
    )
    declare -A flagsArgDict=(
        ["ignore"]="cameras"
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

    # ----------------------------------------- #

    # ---------------------
    ##         main
    # ---------------------
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    yt_newton_3 $@
    return 0
}

alias yt_newton__c="_Newton_c_afterDs9"
function _Newton_c_afterDs9() {
    ## after ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process after ds9
    Please check help of yt_newton_4 ... yt_newton_10
    Inputted options are succeeded to the functions properly.


Options
-h,--help
    show this message

...

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--ignore"]="ignore"
        ["--clean"]="clean"
    )
    declare -A flagsArgDict=(
        ["ignore"]="cameras"
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

    # ----------------------------------------- #

    # ---------------------
    ##         main
    # ---------------------
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}

    yt_newton_4 $@ &&
        yt_newton_5 $@ &&
        yt_newton_6 $@ &&
        yt_newton_7 $@ &&
        yt_newton_8 $@ &&
        yt_newton_9 $@ &&
        yt_newton_10 $@
    return 0
}
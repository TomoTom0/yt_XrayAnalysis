
alias yt_swiftUvot__a="_SwiftUvot_a_ds9"
function _SwiftUvot_a_ds9() {
    ## ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process with ds9
    Please check help of yt_swiftUvot_1
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
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi
    yt_swiftUvot_1 $@
    return 0
}

alias yt_swiftUvot__b="_SwiftUvot_b_afterDs9"
function _SwiftUvot_b_afterDs9() {
    ## after ds9
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    execute the process after ds9
    Please check help of yt_swiftUvot_2 ... yt_swiftUvot_4
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
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi
    yt_swiftUvot_2 $@ &&
        yt_swiftUvot_3 $@ &&
        yt_swiftUvot_4 $@ &&

    return 0
}

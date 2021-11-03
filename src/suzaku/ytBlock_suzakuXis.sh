#!/bin/bash

alias yt_suzakuXis__a="_SuzakuXis_a_ds9"
function _SuzakuXis_a_beforeDs9() {
    ## ds9
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    yt_suzakuXis_1
    return 0
}

alias yt_suzakuXis__b="_SuzakuXis_b_afterDs9"
function _SuzakuXis_b_afterDs9() {
    ## after ds9
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    yt_suzakuXis_2 &&
        yt_suzakuXis_3 &&
        yt_suzakuXis_4 &&
        yt_suzakuXis_5 &&
        yt_suzakuXis_6  ${1:-25}  ${1:-25}&&
        yt_suzakuXis_7
    return 0
}

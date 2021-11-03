#!/bin/bash

alias yt_suzakuHxd__a="_SuzakuHxd_a_all"
function _SuzakuHxd_a_all() {
    ## ds9
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    yt_suzakuHxd_1 &&
        yt_suzakuHxd_2 &&
        yt_suzakuHxd_3 &&
        yt_suzakuHxd_4 &&
        yt_suzakuHxd_5 &&
        yt_suzakuHxd_6 ${1:-25} &&
        yt_suzakuHxd_7

    return 0
}

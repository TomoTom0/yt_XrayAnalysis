#!/bin/bash

alias yt_nustar__a="_Nustar_a_beforeDs9"
function _Nustar_a_beforeDs9() {
    ## before ds9
    declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)}
    yt_nustar_1
    return 0
}

alias yt_nustar__b="_Nustar_b_ds9"
function _Nustar_b_ds9() {
    ## ds9
    declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)}
    yt_nustar_2
    return 0
}

alias yt_nustar__c="_Nustar_c_afterDs9"
function _Nustar_c_afterDs9() {
    ## after ds9
    declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)}
    yt_nustar_3 &&
        yt_nustar_4 &&
        yt_nustar_5 &&
        yt_nustar_6 ${1:-50} &&
        yt_nustar_7
    return 0
}

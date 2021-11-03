#!/bin/bash

alias yt_swiftXrt__a="_SwiftXrt_a_beforeDs9"
function _SwiftXrt_a_beforeDs9() {
    ## before ds9
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
    yt_swiftXrt_1
    return 0
}

alias yt_swiftXrt__b="_SwiftXrt_b_ds9"
function _SwiftXrt_b_ds9() {
    ## ds9
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
    yt_swiftXrt_2
    return 0
}

alias yt_swiftXrt__c="_SwiftXrt_c_afterDs9"
function _SwiftXrt_c_afterDs9() {
    ## after ds9
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
    yt_swiftXrt_3 &&
        yt_swiftXrt_4 &&
        yt_swiftXrt_5 &&
        yt_swiftXrt_6 ${1:-50} &&
        yt_swiftXrt_7
    return 0
}

#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd) # noqa
source ${dir_path}/../../lib/obtain_options.sh

alias yt_swiftXrtBuild_1="_SwiftXrtBuild_1_downloadData"
alias yt_swiftXrtBuild_downloadData="_SwiftXrtBuild_1_downloadData"
function _SwiftXrtBuild_1_downloadData() {
    ## download Data
    # args: url=""
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        cat <<EOF
Usage: ${FUNCNAME[1]} URL [-h,--help] 

${FUNCNAME[1]} URL
    download built Swift XRT spectrum from 1SXPS

URL: download url from 1SXPS (httpXXXX.tar or httpXXX.tar.gz)

Options
--forcePwd
    force working directory to pwd

-h,--help
    show this message

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--forcePwd"]="forcePwd"
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
    url=""
    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${kwargs[0]} ]]; then
            url="${kwargs[0]}"
        fi
        if [[ -n ${flagsIn[forcePwd]} ]]; then
            My_Swift_D=$(pwd)
        fi
    fi
    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi
    cd $My_Swift_D
    if [[ "x${url}" != "x" ]]; then
        prod_ID=$(echo $url | sed -r -n "s/^.*\/USERPROD_([0-9]+)\/.*$/\1/p")
        ext=${url##*.}
        My_Swift_Dir=$My_Swift_D/xrt/xrt_build_${prod_ID}
        mkdir $My_Swift_Dir -p
        if [[ ! -r $My_Swift_Dir ]]; then continue; fi
        cd $My_Swift_Dir
        rm $My_Swift_Dir/* -rf

        tmp_file=tmp.${ext}
        wget $url --no-check-certificate -O $tmp_file
        tar xvf $tmp_file

        if [[ "x${ext}" == "xtar" ]]; then
            ## per ObsID
            cd $My_Swift_Dir/USERPROD_${prod_ID}/spec
            find . -name "*.gz" | xargs -n 1 tar xvf
        elif [[ "x${ext}" == "xgz" ]]; then
            ## Other Cases
            find . -name "*.gz" | xargs -n 1 tar xvf
        fi
    fi
    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrtBuild_2="_SwiftXrtBuild_2_rename"
alias yt_swiftXrtBuild_rename="_SwiftXrtBuild_1_rename"
function _SwiftXrtBuild_2_rename() {
    ## rename and make symbolic link
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        cat <<EOF
Usage: ${FUNCNAME[1]} [-h,--help] 

${FUNCNAME[1]}
    rename and make symbolic link


Options
-h,--help
    show this message

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
    cd $My_Swift_D/xrt
    ## make symbolic link
    prod_IDs=($(find . -maxdepth 1 -type d -printf "%P\n" |
        grep ^xrt_build_[0-9] |
        sed -r -n "s/^xrt_build_([0-9]+)$/\1/p"))
    for prod_ID in ${prod_IDs[@]}; do
        build_path=$My_Swift_D/xrt/xrt_build_${prod_ID}
        spec_path=$build_path/spec
        #### already exists -> continue
        if [[ -r $spec_path ]]; then continue; fi
        #### not exist
        cd $build_path
        if [[ -d "USERPROD_${prod_ID}" ]]; then
            rm $spec_path -f &&
                ln -s $build_path/USERPROD_${prod_ID}/spec $spec_path
        elif [[ x$(find ./ -regex ".*\(pc\|wt\)\.pi" -printf "1") != x ]]; then
            rm $spec_path -f &&
                ln -s $build_path $spec_path
        fi
    done
    cd $My_Swift_D/

    ### edit Header
    cd $My_Swift_D/xrt
    prod_IDs=($(find . -maxdepth 1 -type d -printf "%P\n" |
        grep ^xrt_build_[0-9] |
        sed -r -n "s/^xrt_build_([0-9]+)$/\1/p"))
    for prod_ID in ${prod_IDs[@]}; do
        spec_path=$My_Swift_D/xrt/xrt_build_${prod_ID}/spec
        if [[ ! -r $spec_path ]]; then continue; fi
        cd $spec_path

        rm $spec_path/fit -rf
        mkdir $spec_path/fit -p

        # for per Obs
        obs_IDs=($(find . -name "Obs_*[pw][ct].pi" -printf "%f\n" |
            sed -r -n "s/^\S*Obs_([0-9]+)(pc|wt)\S*$/\1/p"))
        for obs_ID in ${obs_IDs[@]}; do
            tmp_head=Obs_${obs_ID}
            for cam in "pc" "wt"; do
                declare -A tmp_orig_names=(
                    ["${cam}_nongrp"]=${tmp_head}${cam}source.pi
                    ["${cam}_grpauto"]=${tmp_head}${cam}.pi
                    ["${cam}_bkg"]=${tmp_head}${cam}back.pi
                    ["${cam}_rmf"]=${tmp_head}${cam}.rmf
                    ["${cam}_arf"]=${tmp_head}${cam}.arf)

                for key in ${!tmp_orig_names[@]}; do
                    orig_name=${tmp_orig_names[$key]}
                    if [[ ! -f "$orig_name" ]]; then continue; fi
                    new_name=xrtBuild${prod_ID}_Obs${obs_ID}_${key}.fits
                    new_names[$key]=$new_name
                    cp -f $orig_name $spec_path/fit/$new_name
                done
            done
        done

        # for per project
        proj_IDs=($(find . -name "[0-9]*[pw][ct].pi" -printf "%f\n" |
            sed -r -n "s/^([0-9]+)(pc|wt)\S*$/\1/p"))
        for proj_ID in ${proj_IDs[@]}; do
            tmp_head=${proj_ID}
            for cam in "pc" "wt"; do
                declare -A tmp_orig_names=(
                    ["${cam}_nongrp"]=${tmp_head}${cam}source.pi
                    ["${cam}_grpauto"]=${tmp_head}${cam}.pi
                    ["${cam}_bkg"]=${tmp_head}${cam}back.pi
                    ["${cam}_rmf"]=${tmp_head}${cam}.rmf
                    ["${cam}_arf"]=${tmp_head}${cam}.arf)

                for key in ${!tmp_orig_names[@]}; do
                    orig_name=${tmp_orig_names[$key]}
                    if [[ ! -f "$orig_name" ]]; then continue; fi
                    new_name=xrtBuild${prod_ID}_Proj${proj_ID}_${key}.fits
                    new_names[$key]=$new_name
                    cp -f $orig_name $spec_path/fit/$new_name
                done
            done
        done
    done
    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrtBuild_3="_SwiftXrtBuild_3_grppha"
alias yt_swiftXrtBuild_grppha="_SwiftXrtBuild_3_grppha"
function _SwiftXrtBuild_3_grppha() {
    ## grppha
    # args: gnum=10
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        cat <<EOF
Usage: ${FUNCNAME[1]} [--gnum GNUM] [-h,--help] 

${FUNCNAME[1]}
    grouping with grppha


Options
--gnum GNUM
    change gnum for Swift XRT

-h,--help
    show this message

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--gnum"]="gnum"
    )
    declare -A flagsArgDict=(
        ["gnum"]="gnum"
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
    declare -A gnum=10
    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${kwargs[gnum__gnum]} ]]; then
            declare -i gnum=${kwargs[gnum__gnum]}
        fi
    fi

    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi
    cd $My_Swift_D/xrt
    function _ObtainExtNum(){
        tmp_fits="$1"
        extName="${2:-SPECTRUM}"
        if [[ -n "${tmp_fits}" ]]; then
            _tmp_extNums=($(fkeyprint infile=$tmp_fits keynam=EXTNAME |
                grep -B 1 $extName |
                sed -r -n "s/^.*#\s*EXTENSION:\s*([0-9]+)\s*$/\1/p"))
        else
            _tmp_extNums=(0)
        fi
        echo ${_tmp_extNums[0]:-0}
    }
    prod_IDs=($(find . -maxdepth 1 -type d -printf "%P\n" |
        grep ^xrt_build_[0-9] |
        sed -r -n "s/^xrt_build_([0-9]+)$/\1/p"))
    for prod_ID in ${prod_IDs[@]}; do
        spec_path=$My_Swift_D/xrt/xrt_build_${prod_ID}/spec
        if [[ ! -r $spec_path ]]; then continue; fi
        cd $spec_path/fit

        nongrp_names=($(find . -name "xrtBuild*_nongrp.fits" -printf "%f\n"))
        for nongrp_name in ${nongrp_names[@]}; do
            tmp_head=${nongrp_name/_nongrp.fits/}
            grp_name=${tmp_head}_grp${gnum}.fits
            grpAuto_name=${tmp_head}_grpauto.fits
            nongrpExtNum=$(_ObtainExtNum $nongrp_name SPECTRUM)
            grpAutoExtNum=$(_ObtainExtNum $grpAuto_name SPECTRUM)

            declare -A tr_keys=(
                ["BACKFILE"]=${tmp_head}_bkg.fits
                ["RESPFILE"]=${tmp_head}_rmf.fits
                ["ANCRFILE"]=${tmp_head}_arf.fits)

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile="${nongrp_name}+${nongrpExtNum}" \
                    keyword="${key}" add=yes
            done

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile="${grpAuto_name}+${grpAutoExtNum}" \
                    keyword="${key}" add=yes
            done
            if [[ $gnum -le 0 ]]; then continue; fi
            cat <<EOF | bash
grppha infile=$nongrp_name outfile=$grp_name
group min $gnum
exit !$grp_name
EOF

        done
    done
    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrtBuild_4="_SwiftXrtBuild_4_fitDirectory"
alias yt_swiftXrtBuild_fitDirectory="_SwiftXrtBuild_4_fitDirectory"
function _SwiftXrtBuild_4_fitDirectory() {
    ## fitディレクトリにまとめ
    # args: FLAG_hardCopy=false
    # args: FLAG_symbLink=false
    # args: tmp_prefix="xrtBuild"

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--hardCopy] [--symbLink] ..." 1>&2
        cat <<EOF

${FUNCNAME[1]}
    move files to fit directory
    This process has two steps:
        1. copy files to ./fit
        2. generate symbolic link to ../fit


Options
-h,--help
    show this message

--hardCopy
    hard copy instead of generating symbolic link to $(../fit) (Step 2.)

--symbLink
    generate symbolic link instead of copy to $(./fit) (Step 1.)

--prefixName prefixName
    select the prefix of file names to move

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--hardCopy"]="hardCopy"
        ["--symbLink"]="symbLink"
        ["--prefixName"]="prefixName"
    )
    declare -A flagsArgDict=(
        ["prefixName"]="name"
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
    FLAG_hardCopy=false
    FLAG_symbLink=false
    tmp_prefix=xrtBuild
    if [[ x${FUNCNAME} == x ]]; then
        if [[ -n "${flagsIn[hardCopy]}" ]]; then
            FLAG_hardCopy=true
        fi
        if [[ -n "${flagsIn[symbLink]}" ]]; then
            FLAG_symbLink=true
        fi
        if [[ -n "${kwargs[prefixName__name]}" ]]; then
            tmp_prefix=${kwargs[prefixName__name]}
        fi
    fi
    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Swift_D
    mkdir -p $My_Swift_D/fit $My_Swift_D/../fit
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Swift_ID in ${obs_dirs[@]}; do
        prod_IDs=($(find . -maxdepth 1 -type d -printf "%P\n" |
            grep ^xrt_build_[0-9] |
            sed -r -n "s/^xrt_build_([0-9]+)$/\1/p"))
        for prod_ID in ${prod_IDs[@]}; do
            if [[ ${FLAG_symbLink:=false} == "true" ]]; then
                find "$My_Swift_D/xrt//xrt_build_${prod_ID}/spec/fit/" -name "${tmp_prefix}*.*" \
                    -type f -printf "%f\n" |
                    xargs -n 1 -i rm -f $My_Swift_D/fit/{}
                find "$My_Swift_D/xrt//xrt_build_${prod_ID}/spec/fit/" -name "${tmp_prefix}*.*" -type f -printf "%p\n" |
                    xargs -i ln -s {} $My_Swift_D/fit/
            else
                find "$My_Swift_D/xrt//xrt_build_${prod_ID}/spec/fit/" -name "${tmp_prefix}*.*" -type f -printf "%p\n" |
                    xargs -i cp {} $My_Swift_D/fit/
            fi
        done
    done
    if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
        cp -f $My_Swift_D/fit/${tmp_prefix}*.* $My_Swift_D/../fit/
    else
        # remove the files with the same name as new files
        find $My_Swift_D/fit/ -name "${tmp_prefix}*.*" -type f -printf "%f\n" |
            xargs -n 1 -i rm -f $My_Swift_D/../fit/{}
        # generate symbolic links
        ln -s $My_Swift_D/fit/${tmp_prefix}*.* $My_Swift_D/../fit/
    fi
    # remove broken symbolic links
    find -L $My_Swift_D/../fit/ -type l -delete
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

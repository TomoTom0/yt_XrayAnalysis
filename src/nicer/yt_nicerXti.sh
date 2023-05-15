#!/bin/bash

dir_path=$(
    cd $(dirname ${BASH_SOURCE:-$0})
    pwd
) # noqa
source ${dir_path}/../../lib/obtain_options.sh

alias yt_nicerXti_1="_NicerXti_1_products"
alias yt_nicerXti_products="_NicerXti_1_products"
function _NicerXti_1_products() {
    ## xti products
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat <<EOF

${FUNCNAME[1]}
    many files will be generated with nuproductus


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
        My_Nicer_D=${My_Nicer_D:=$(pwd)}
    else
        declare -g My_Nicer_D=${My_Nicer_D:=$(pwd)}
    fi # 未定義時に代入
    cd $My_Nicer_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Nicer_ID in ${obs_dirs[@]}; do

        My_Nicer_Dir=$My_Nicer_D/$My_Nicer_ID
        if [[ ! -r $My_Nicer_Dir/xti/event_cl ]]; then continue; fi

        cd $My_Nicer_Dir/xti/event_cl

        _evt_tmps=($(find . -name "ni${My_Nicer_ID}_0mpu7_cl.evt*" -printf "%f\n"))
        evt_file=${_evt_tmps[-1]}

        rm -f nicerXti__*.fits
        cat <<EOF | bash
xselect
xsel
read events ${evt_file}
./
y
extract all
extract spectrum
save spectrum nicerXti__nongrp.fits
exit
n
EOF

        # arf, rmfをcopy
        _arf_files=($(find $CALDB/data/nicer/xti/cpf/arf/ -name "*.arf"))
        _rmf_files=($(find $CALDB/data/nicer/xti/cpf/rmf/ -name "*.rmf"))
        cp -f ${_arf_files[-1]} nicerXti__arf.fits
        cp -f ${_rmf_files[-1]} nicerXti__rmf.fits

        mkdir fit -p
        mv nicerXti__*.fits fit/

    done
    cd $My_Nicer_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_nicerXti_2="_NicerXti_2_obtainBkg"
alias yt_nicerXti_obtainBkg="_NicerXti_2_obtainBkg"
function _NicerXti_2_obtainBkg() {
    ## obtain bkg
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--rmf] [--arf]" 1>&2
        cat <<EOF

${FUNCNAME[1]}
    make Bkg


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
        My_Nicer_D=${My_Nicer_D:=$(pwd)}
    else
        declare -g My_Nicer_D=${My_Nicer_D:=$(pwd)}
    fi # 未定義時に代入
    cd $My_Nicer_D

    # nibackestimator
    if [[ -x $(which nibkgestimator) ]]; then
        obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
        for My_Nicer_ID in ${obs_dirs[@]}; do

            My_Nicer_Dir=$My_Nicer_D/$My_Nicer_ID
            if [[ ! -r $My_Nicer_Dir/xti/event_cl/fit ]]; then continue; fi

            cd $My_Nicer_Dir/xti/event_cl/fit

            # toolの兼ね合いで名前を.phaに変更
            ln -nfs nicerXti__nongrp.fits ni${My_Nicer_ID}.pha
            rm -f ni${My_Nicer_ID}_bkg.pha

            # mkf3存在確認
            if [[ -f $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf3 ]]; then
                :
            elif [[ -f $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf2 ]]; then
                # mkf2からmkf3作成
                niaddkp $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf2
            elif [[ -f $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf.gz ]]; then
                # mkf -> mkf2
                niprefilter2 indir=${My_Nicer_Dir} infile=${My_Nicer_Dir}/auxil/ni${My_Nicer_ID}.mkf.gz outfile=${My_Nicer_Dir}/auxil/ni${My_Nicer_ID}.mkf2
                # mkf2 -> mkf3
                niaddkp $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf2
            else
                # mkfもないなら無理
                continue
            fi

            # bk作成
            nibkgestimator ni${My_Nicer_ID}.pha $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf3 --bkg_evt $CALDB/data/nicer/xti/pcf/30nov18targskc_enhanced.evt
            # 名前を調整
            #mv ni${My_Nicer_ID}.pha ni${My_Nicer_ID}_nongrp.fits
            mv ni${My_Nicer_ID}_bkg.pha nicerXti__esti_bkg.fits
        done
    fi

    # nibackgen3C50
    # NIBACKGEN3C50_MODEL_PATH の判定
    if [[ -x $(which nibackgen3C50) ]] && [[ -x ${NIBACKGEN3C50_MODEL_PATH} ]]; then
        ni3C50_bin_path=$(cd $(dirname $(readlink -f $(which nibackgen3C50))); pwd )
        ni3C50_bkg_path=${ni3C50_bin_path}/../
        obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
        for My_Nicer_ID in ${obs_dirs[@]}; do

            My_Nicer_Dir=$My_Nicer_D/$My_Nicer_ID
            if [[ ! -r $My_Nicer_Dir/xti/event_cl/fit ]]; then continue; fi

            cd $My_Nicer_Dir/xti/event_cl/fit

            #mkdir $My_Nicer_Dir/xti/out3C50 -p
            #mv $My_Nicer_Dir/xti/out3C50
            ln -nfs nicerXti__nongrp.fits nibackgen3C50_tot.pi
            rm nibackgen3C50_bkg.pi -f

            nibackgen3C50 rootdir=$My_Nicer_D obsid=$My_Nicer_ID bkgdir=${NIBACKGEN3C50_MODEL_PATH} #~/mylib/soft/nicer/nibackgen3C50/bg_model_3C50_RGv5

            #mv nibackgen3C50_tot.pi ni3C50_${My_Nicer_ID}_nongrp.fits
            mv nibackgen3C50_bkg.pi nicerXti__3C50_bkg.fits

        done
    fi


    cd $My_Nicer_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}


alias yt_nicerXti_3="_NicerXti_3_editHeader"
alias yt_nicerXti_editHeader="_NicerXti_3_editHeader"
function _NicerXti_3_editHeader() {
    ## edit header
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--minimum] [--strict] ..." 1>&2
        cat <<EOF

${FUNCNAME[1]}
    generate Bkg with nibackgen3C50


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
        My_Nicer_D=${My_Nicer_D:=$(pwd)}
    else
        declare -g My_Nicer_D=${My_Nicer_D:=$(pwd)}
    fi # 未定義時に代入
    cd $My_Nicer_D

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

    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Nicer_ID in ${obs_dirs[@]}; do

        My_Nicer_Dir=$My_Nicer_D/$My_Nicer_ID
        if [[ ! -r $My_Nicer_Dir/xti/event_cl/fit ]]; then continue; fi

        cd $My_Nicer_Dir/xti/event_cl/fit

        find . -name "nicerXti__*" |
            rename -f "s/nicerXti__/nicerXti_${My_Nicer_ID}_/"

        # bkgにあわせて2つにCOPY
        nongrp_name=nicerXti_${My_Nicer_ID}_nongrp.fits
        nongrpExtNum=$(_ObtainExtNum $nongrp_name SPECTRUM)

        declare -A tr_keys=(
            ["BACKFILE"]=nicerXti_${My_Nicer_ID}_3C50_bkg.fits
            ["RESPFILE"]=nicerXti_${My_Nicer_ID}_rmf.fits
            ["ANCRFILE"]=nicerXti_${My_Nicer_ID}_arf.fits)

        for key in ${!tr_keys[@]}; do
            fparkey value="${tr_keys[$key]}" \
                fitsfile="${nongrp_name}+${nongrpExtNum}" \
                keyword="${key}" add=yes
        done

    done

    cd $My_Nicer_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_nicerXti_4="_NicerXti_4_grppha"
alias yt_nicerXti_grppha="_NicerXti_4_grppha"
function _NicerXti_4_grppha() {
    ## grppha
    # args: gnum=50
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--gnum GNUM] ..." 1>&2
        cat <<EOF

${FUNCNAME[1]}
    do grouping with grppha
    In default, this function uses "group min GNUM" for grouping
    If gnum for a camera is less than or equal to 0, then the grouping will be skipped.


Options
--gnum GNUM
    change gnum

-h,--help
    show this message

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
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
    declare -A gnum=50
    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${kwargs[gnum__gnum]} ]]; then
            declare -i gnum=${kwargs[gnum__gnum]}
        fi
    fi
    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then
        My_Nicer_D=${My_Nicer_D:=$(pwd)}
    else
        declare -g My_Nicer_D=${My_Nicer_D:=$(pwd)}
    fi # 未定義時に代入
    cd $My_Nicer_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Nicer_ID in ${obs_dirs[@]}; do

        My_Nicer_Dir=$My_Nicer_D/$My_Nicer_ID
        if [[ ! -r $My_Nicer_Dir/xti/event_cl/fit ]]; then continue; fi

        cd $My_Nicer_Dir/xti/event_cl/fit
        nongrp_name=nicerXti_${My_Nicer_ID}_nongrp.fits
        grp_name=nicerXti_${My_Nicer_ID}_grp${gnum}.fits
        rm $grp_name -f
        cat <<EOF | bash
grppha infile=$nongrp_name outfile=$grp_name
group min ${gnum}
exit !$grp_name
EOF

    done
    cd $My_Nicer_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_nicerXti_5="_NicerXti_5_fitDirectory"
alias yt_nicerXti_fitDirectory="_NicerXti_5_fitDirectory"
function _NicerXti_5_fitDirectory() {
    ## fitディレクトリにまとめ
    # args: FLAG_hardCopy=false
    # args: FLAG_symbLink=false
    # args: tmp_prefix="xrt_"

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
    tmp_prefix="nicerXti_"
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
        My_Nicer_D=${My_Nicer_D:=$(pwd)}
    else
        declare -g My_Nicer_D=${My_Nicer_D:=$(pwd)}
    fi # 未定義時に代入
    cd $My_Nicer_D
    mkdir -p $My_Nicer_D/fit $My_Nicer_D/../fit
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Nicer_ID in ${obs_dirs[@]}; do
        fit_path=$My_Nicer_D/$My_Nicer_ID/xti/event_cl/fit
        if [[ ${FLAG_symbLink:=false} == "true" ]]; then
            #find $fit_path -name "${tmp_prefix}*.*" \
            #    -type f -printf "%f\n" |
            #    xargs -n 1 -i rm -f $My_Nicer_D/fit/{}
            ln -nfs ${fit_path}/${tmp_prefix}* ${My_Nicer_D}/fit/
        else
            if [[ ! -d "$fit_path" ]]; then continue; fi
            find $fit_path -name "${tmp_prefix}*" | xargs -i cp {} ${My_Nicer_D}/fit/
            #cp -f $fit_path/${tmp_prefix}* ${My_Nicer_D}/fit/
        fi
    done
    if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
        cp -f $My_Nicer_D/fit/${tmp_prefix}*.* $My_Nicer_D/../fit/
    else
        # remove the files with the same name as new files
        #find $My_Nicer_D/fit/ -name "${tmp_prefix}*.*" \
        #    -type f -printf "%f\n" |
        #    xargs -n 1 -i rm -f $My_Nicer_D/../fit/{}
        # generate symbolic links
        ln -nfs $My_Nicer_D/fit/${tmp_prefix}*.* $My_Nicer_D/../fit/
    fi
    # remove broken symbolic links
    find -L $My_Nicer_D/../fit/ -type l -delete
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

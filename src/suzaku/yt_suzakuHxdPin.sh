#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd) # noqa
source ${dir_path}/../../lib/obtain_options.sh


alias yt_suzakuHxdPin_1="_SuzakuHxdPin_1_obtainNxb"
alias yt_suzakuHxdPin_obtainNxb="_SuzakuHxdPin_1_obtainNxb"
function _SuzakuHxdPin_1_obtainNxb() {
    ## download NXB (Non X-ray Background source)
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    download NXB event file from jaxa


Options
--canSkip
    If the NXB event file exists, downloading will be skipped or not.
    DEFAULT: no

-h,--help
    show this message


EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--canSkip"]="canSkip"
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
    FLAG_canSkip=false
    if [[ x${FUNCNAME} == x ]]; then
        if [[ -n "${flagsIn[canSkip]}" ]]; then
            FLAG_canSkip=true
        fi
    fi
    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    else 
        declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    fi
    cd $My_Suzaku_D
    nxb_evt=ae_hxdPin_nxb.evt

    function _mjd2date() {
        if (($# == 0)); then
            args=$(cat /dev/stdin)
        else
            args=$@
        fi
        date_strings=($args)
        for mjd_str in ${args[@]}; do
            mjd_tmp=$(echo ${mjd_str} | sed s/^.*([0-9]+).*$/\1/)
            val_n=$(($mjd_tmp + 678881))
            val_a1=$((4 * ($val_n + 1) / 146097 + 1))
            val_a2=$((3 * $val_a1 / 4))
            val_a=$((4 * $val_n + 3 + 4 * $val_a2))
            val_b1=$(($val_a % 1461 / 4))
            val_b=$((5 * $val_b1 + 2))
            y=$(($val_a / 1461))
            m=$(($val_b / 153 + 3))
            d=$(($val_b % 153 / 5 + 1))
            if [[ $m -ge 13 ]]; then
                y=$(($y + 1))
                m=$(($m - 12))
            fi
            echo "$y-$m-$d"
        done
    }

    function _Obtain_SuzakuHxdPin_NxbEvt() {
        mjd_str=$1
        date_str=$(_mjd2date $mjd_str)
        date_list=(${date_str//-/ })
        y=$(echo ${date_list[0]} | sed s/^.*([0-9]+).*$/\1/)
        m=$(echo ${date_list[1]} | sed s/^.*([0-9]+).*$/\1/ | printf "%02i" $(cat))
        if [[ $mjd_str -ge 56139 ]]; then # 2012-7-31
            version=2.2
        else
            version=2.0
        fi
        #url="http://www.astro.isas.jaxa.jp/suzaku/analysis/hxd/pinnxb/pinnxb_ver${version}_tuned/${y}_${m}/ae${My_Suzaku_ID}_hxd_pinbgd.evt.gz"
        url="https://data.darts.isas.jaxa.jp/pub/suzaku/background/hxd/pinnxb/pinnxb_ver${version}_tuned/${y}_${m}/ae${My_Suzaku_ID}_hxd_pinbgd.evt.gz"
        wget $url --no-check-certificate -O ${nxb_evt}
    }

    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

        cd $My_Suzaku_Dir
        if [[ -r ${nxb_evt} && ${FLAG_canSkip:=false} == true ]]; then continue; fi

        _pin_tmps=($(ls ae${My_Suzaku_ID}hxd_0_pinno_cl*.evt*))
        pin_file=${_pin_tmps[0]}
        obs_MJD_tmp_float=($(fkeyprint infile="${pin_file}" keynam="MJD-OBS" |
            grep "MJD-OBS\s*=" |
            sed -r -n "s/^.*MJD-OBS\s*=\s*(.*)\s*\/.*$/\1/p"))
        obs_MJD=$(printf "%.0f" ${obs_MJD_tmp_float[0]})
        _Obtain_SuzakuHxdPin_NxbEvt $obs_MJD
        # ${nxb_evt}
    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi

}

alias yt_suzakuHxdPin_2="_SuzakuHxdPin_2_products"
alias yt_suzakuHxdPin_products="_SuzakuHxdPin_2_products"
function _SuzakuHxdPin_2_products() {
    ## hxdpinxbpi
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        cat << EOF
Usage: ${FUNCNAME[1]} [-h,--help] ...

${FUNCNAME[1]}
    hxdpinxbpi


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
        ["--canSkip"]="canSkip"
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
        My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    else 
        declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    fi
    cd $My_Suzaku_D
    nxb_evt=ae_hxdPin_nxb.evt

    function _Obtain_SuzakuHxdPin_RspIndex() {
        input_mjd=${1%%\.[0-9]*}
        date_standards=(53600 53881 54012 54311 54710 55106 55213 55229 55290 55532 55708)
        count=0
        for data_stan in ${date_standards[@]}; do
            if [[ ! $input_mjd =~ [0-9]+ ||
                $data_stan -ge $input_mjd ]]; then
                break
            fi
            count=$(($count + 1))
        done
        echo $count
    }

    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

        cd $My_Suzaku_Dir
        _pin_tmps=($(ls ae${My_Suzaku_ID}hxd_0_pinno_cl*.evt*))
        pin_file=${_pin_tmps[0]}

        _pse_tmp=($(ls ae${My_Suzaku_ID}hxd_0_pse_cl*.evt*))
        pse_file=${_pse_tmp[0]}

        ### merge gti
        gti_file=tmp_pin.gti
        rm $gti_file -f &&
            mgtime ingtis="${pin_file}+2,tmp_nxb.evt+2" \
                outgti=$gti_file merge="AND"

        hxdpinxbpi input_fname=${pin_file} pse_event_fname=${pse_file} \
            bkg_event_fname=${nxb_evt} outstem=tmp_ \
            gti_fname=$gti_file cxb_fname=CALC \
            groupspec=yes clobber=yes

        obs_MJD_tmp_float=($(fkeyprint infile="${pin_file}" keynam="MJD-OBS" |
            grep "MJD-OBS\s*=" |
            sed -r -n "s/^.*MJD-OBS\s*=\s*(.*)\s*\/.*$/\1/p"))
        obs_MJD=$(printf "%.0f" ${obs_MJD_tmp_float[0]})

        rsp_index=$(_Obtain_SuzakuHxdPin_RspIndex ${obs_MJD})
        rsp_files_CALDB=($(find $CALDB/data/suzaku/hxd/cpf/ -name "ae_hxd_pinhxnome${rsp_index}*.rsp"))
        rspFlat_files_CALDB=($(find $CALDB/data/suzaku/hxd/cpf/ -name "ae_hxd_pinflate${rsp_index}*.rsp"))
        #_rsp_tmps=($(find . -name "ae_hxd_pinxnome*.rsp" -printf "%f\n")  ${rsp_files_CALDB[@]})
        rsp_file=${rsp_files_CALDB[-1]}
        #_rspFlat_tmps=($(find . -name "ae_hxd_pinflate*.rsp" -printf "%f\n") ${rsp_files_CALDB[@]})
        rspFlat_file=${rsp_files_CALDB[-1]}

        rm -f hxdPin__rmf.fits hxdPin__rmfFlat.fits
        ln -s ${rsp_file} hxdPin__rmf.fits
        ln -s ${rspFlat_file} hxdPin__rmfFlat.fits

        declare -A rename_dic=(
            ["tmp_hxd_pin_sr.pi"]=hxdPin__nongrp.fits
            ["tmp_hxd_pin_sr_grp.pi"]=hxdPin__grpauto.fits
            ["tmp_hxd_pin_bg.pi"]=hxdPin__bkg.fits
            ["tmp_hxd_pin_nxb.pi"]=hxdPin__nxb.fits
            ["tmp_hxd_pin_cxb.pi"]=hxdPin__cxb.fits
            )
        for oldName in ${!rename_dic[@]}; do
            mv -f $oldName ${rename_dic[$oldName]}
        done
        rm ${My_Suzaku_Dir}/fitPin -rf
        mkdir ${My_Suzaku_Dir}/fitPin -p
        mv -f hxdPin__* ${My_Suzaku_Dir}/fitPin

    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}


alias yt_suzakuHxdPin_3="_SuzakuHxdPin_3_editHeader"
alias yt_suzakuHxdPin_editHeader="_SuzakuHxdPin_3_editHeader"
function _SuzakuHxdPin_3_editHeader() {
    ## edit header

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        cat <<EOF
Usage: ${FUNCNAME[1]} [-h,--help] [--minimum] [--strict] ...

${FUNCNAME[1]}
    add the file names of bkg, rmf and arf for Xspec to fits header.


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
        My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    else 
        declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    fi
    cd $My_Suzaku_D
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
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir/fitPin ]]; then continue; fi

        cd $My_Suzaku_Dir/fitPin
        find . -name "hxdPin__*" | rename -f "s/hxdPin__/hxdPin_${My_Suzaku_ID}_/"
        for nongrp_name in $(find . -name "hxdPin_[0-9]*_nongrp.fits" -printf "%f\n"); do
            grp_name=${nongrp_name/_nongrp.fits/_grp${grp_num}.fits}
            nongrpExtNum=$(_ObtainExtNum $nongrp_name SPECTRUM)
            declare -A tr_keys=(
                ["RESPFILE"]=hxdPin_${My_Suzaku_ID}_rmf.fits
                ["BACKFILE"]=hxdPin_${My_Suzaku_ID}_bkg.fits)

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile="${nongrp_name}+${nongrpExtNum}" \
                    keyword="${key}" add=yes
            done

        done

    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuHxdPin_4="_SuzakuHxdPin_4_grppha"
alias yt_suzakuHxdPin_grppha="_SuzakuHxdPin_4_grppha"
function _SuzakuHxdPin_4_grppha() {
    ## grppha
    # args: gnum=25

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
    change gnum for HXD/PIN


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
    declare -A gnum=25
    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${kwargs[gnum__gnum]} ]]; then
            declare -i gnum=${kwargs[gnum__gnum]}
        fi
    fi

    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    else 
        declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    fi
    cd $My_Suzaku_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir/fitPin ]]; then continue; fi

        cd $My_Suzaku_Dir/fitPin
        for nongrp_name in $(find . -name "hxdPin_[0-9]*_nongrp.fits" -printf "%f\n"); do
            grp_name=${nongrp_name/_nongrp.fits/_grp${gnum}.fits}

            rm $grp_name -f
            cat <<EOF | bash
grppha infile=${nongrp_name} outfile=${grp_name}
group min ${gnum}
exit !${grp_name}
EOF

        done
    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuHxdPin_5="_SuzakuHxdPin_5_fitDirectory"
alias yt_suzakuHxdPin_fitDirectory="_SuzakuHxdPin_5_fitDirectory"
function _SuzakuHxdPin_5_fitDirectory() {
    ##    to fit directory
    # args: FLAG_hardCopy=false
    # args: FLAG_symbLink=false
    # args: tmp_prefix="hxdPin_"

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
    tmp_prefix="hxdPin_"
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
        My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    else 
        declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    fi
    cd $My_Suzaku_D

    mkdir -p $My_Suzaku_D/fit $My_Suzaku_D/../fit
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        if [[ ${FLAG_symbLink:=false} == "true" ]]; then
            find $My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl/fit/ -name "${tmp_prefix}*.*" \
                -type f -printf "%f\n" |
                xargs -n 1 -i rm -f $My_Suzaku_D/fit/{}
            ln -s $My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl/fit/${tmp_prefix}* ${My_Suzaku_D}/fit/
        else
            cp -f $My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl/fit/${tmp_prefix}* ${My_Suzaku_D}/fit/
        fi
    done
    if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
        cp -f $My_Suzaku_D/fit/${tmp_prefix}*.* $My_Suzaku_D/../fit/
    else
            # remove the files with the same name as new files
        find $My_Suzaku_D/fit/ -name "${tmp_prefix}*.*" \
            -type f -printf "%f\n" |
            xargs -n 1 -i rm -f $My_Suzaku_D/../fit/{}
        # generate symbolic links
        ln -s $My_Suzaku_D/fit/${tmp_prefix}*.* $My_Suzaku_D/../fit/
    fi
    # remove broken symbolic links
    find -L $My_Suzaku_D/../fit/ -type l -delete

    cd $My_Suzaku_D

    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}



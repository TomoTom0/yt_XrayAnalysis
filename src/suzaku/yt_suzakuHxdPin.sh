#!/bin/bash

alias yt_suzakuHxd_1="_SuzakuHxd_1_obtainNxb"
alias yt_suzakuHxd_obtainNxb="_SuzakuHxd_1_obtainNxb"
function _SuzakuHxd_1_obtainNxb() {
    ## download NXB (Non X-ray Background source)
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D

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

    function _Obtain_SuzakuHxd_NxbPha() {
        mjd_str=$1
        date_str=$(_mjd2date $mjd_str)
        date_list=(${date_str//-/ })
        y=$(echo ${date_list[0]} | sed s/^.*([0-9]+).*$/\1/)
        m=$(echo ${date_list[1]} | sed s/^.*([0-9]+).*$/\1/ | printf "%02i" $(cat))
        if [[ $mjd_str -ge 56139 ]]; then
            version=2.2
        else
            version=2.0
        fi
        url="http://www.astro.isas.jaxa.jp/suzaku/analysis/hxd/pinnxb/pinnxb_ver${version}_tuned/${y}_${m}/ae${My_Suzaku_ID}_hxd_pinbgd.evt.gz"
        wget $url -O tmp_nxb.evt
    }

    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

        cd $My_Suzaku_Dir

        _pin_tmps=($(ls ae${My_Suzaku_ID}hxd_0_pinno_cl*.evt*))
        pin_file=${_pin_tmps[0]}
        obs_MJD_tmp_float=($(fkeyprint infile="${pin_file}" keynam="MJD-OBS" |
            grep "MJD-OBS\s*=" |
            sed -r -n "s/^.*MJD-OBS\s*=\s*(.*)\s*\/.*$/\1/p"))
        obs_MJD=$(printf "%.0f" ${obs_MJD_tmp_float[0]})
        _Obtain_SuzakuHxd_NxbPha $obs_MJD
        # tmp_nxb.evt
    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi

}

alias yt_suzakuHxd_2="_SuzakuHxd_2_obtainRspGti"
alias yt_suzakuHxd_obtainRspGti="_SuzakuHxd_2_obtainRspGti"
function _SuzakuHxd_2_obtainRspGti() {
    ## set rsp, gti
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D

    function _Obtain_SuzakuHxd_RspIndex() {
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

    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

        cd $My_Suzaku_Dir
        _pin_tmps=($(ls ae${My_Suzaku_ID}hxd_0_pinno_cl*.evt*))
        pin_file=${_pin_tmps[0]}

        obs_MJD_tmp_float=($(fkeyprint infile="${pin_file}" keynam="MJD-OBS" |
            grep "MJD-OBS\s*=" |
            sed -r -n "s/^.*MJD-OBS\s*=\s*(.*)\s*\/.*$/\1/p"))
        obs_MJD=$(printf "%.0f" ${obs_MJD_tmp_float[0]})

        rsp_index=$(_Obtain_SuzakuHxd_RspIndex ${obs_MJD})
        _rsp_tmps=($(ls $CALDB/data/suzaku/hxd/cpf/ae_hxd_pinhxnome${rsp_index}*.rsp))
        rsp_file=${_rsp_tmps[-1]}
        _rsp_flat_tmps=($(ls $CALDB/data/suzaku/hxd/cpf/ae_hxd_pinflate${rsp_index}*.rsp))
        rsp_flat_file=${_rsp_flat_tmps[-1]}

        rm -f hxd__src.rmf hxd__flat.rmf
        ln -s ${rsp_file} hxd__src.rmf
        ln -s ${rsp_flat_file} hxd__flat.rmf

        ## merge gti
        gti_file=tmp_pin.gti
        rm $gti_file -f &&
            mgtime ingtis="${pin_file}+2,tmp_nxb.evt+2" \
                outgti=$gti_file merge="AND"
    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuHxd_3="_SuzakuHxd_3_xselect"
alias yt_suzakuHxd_xselect="_SuzakuHxd_3_xselect"
function _SuzakuHxd_3_xselect() {
    ## extract spec
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

        cd $My_Suzaku_Dir
        _pin_tmps=($(ls ae${My_Suzaku_ID}hxd_0_pinno_cl*.evt*))
        pin_file=${_pin_tmps[0]}
        gti_file=tmp_pin.gti

        rm tmp_hxd_src.pha tmp_hxd_nxb.pha -f
        cat <<EOF | bash
xselect
xsel
read event ${pin_file}
./
filter time file $gti_file
set PHANAME PI_PIN
extract spec
save spec tmp_hxd_nongrp.fits
read event tmp_nxb.evt
filter time file $gti_file
set PHANAME PI_PIN
extract spec
save spec tmp_hxd_nxb.fits
exit
n
EOF
    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuHxd_4="_SuzakuHxd_4_corrections"
alias yt_suzakuHxd_corrections="_SuzakuHxd_4_corrections"
function _SuzakuHxd_4_corrections() {
    ## dead time correction and BGD EXPOSURE correction
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

        cd $My_Suzaku_Dir
        ### dead time correction

        pse_file_tmp=($(ls ae${My_Suzaku_ID}hxd_0_pse_cl*.evt*))
        pse_file=${pse_file_tmp[0]}

        new_src_file=hxd__nongrp.fits
        cp tmp_hxd_nongrp.fits $new_src_file
        hxddtcor event_fname=${pse_file} \
            pi_fname=$new_src_file \
            save_pseudo=no chatter=2
        #### dead time correction is no longer required for nxb

        ### scale down of pin BGD flux
        pha_file=tmp_hxd_nxb.fits

        new_pha_file=${pha_file/tmp_hxd_/hxd__}
        rm $new_pha_file -f &&
            fcalc $pha_file $new_pha_file EXPOSURE "ONTIME * 10.0"

        rm $My_Suzaku_Dir/fit -rf
        mkdir $My_Suzaku_Dir/fit -p
        mv hxd__* $My_Suzaku_Dir/fit -f

    done
    cd $My_Suzaku_D

    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuHxd_5="_SuzakuHxd_5_editHeader"
alias yt_suzakuHxd_editHeader="_SuzakuHxd_5_editHeader"
function _SuzakuHxd_5_editHeader() {
    ## edit header
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi

        cd $My_Suzaku_Dir/fit
        find . -name "hxd__*" | rename -f "s/hxd__/hxd_${My_Suzaku_ID}_/"
        for nongrp_name in $(ls hxd_[0-9]*_nongrp.fits); do
            grp_name=${nongrp_name/_nongrp.fits/_grp${grp_num}.fits}

            declare -A tr_keys=(
                ["RESPFILE"]=hxd_${My_Suzaku_ID}_src.rmf
                ["BACKFILE"]=hxd_${My_Suzaku_ID}_nxb.fits)

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile=${nongrp_name} \
                    keyword="${key}" add=yes
            done

        done

    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuHxd_6="_SuzakuHxd_6_grppha"
alias yt_suzakuHxd_grppha="_SuzakuHxd_6_grppha"
function _SuzakuHxd_6_grppha() {
    ## grppha
    # args: gnum=25
    if [[ x${FUNCNAME} != x ]]; then
        _gnum_tmp=${1:=25}
        if [[ $_gnum_tmp =~ [0-9]+ ]]; then
            gnum=$_gnum_tmp
        else
            gnum=25
        fi
    else
        gnum=25
    fi
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi

        cd $My_Suzaku_Dir/fit
        for nongrp_name in $(find . -name "hxd_[0-9]*_nongrp.fits" -printf "%f\n"); do
            grp_name=${nongrp_name/_nongrp.fits/_grp${grp_num}.fits}

            rm $grp_name -f
            cat <<EOF | bash
grppha infile=${nongrp_name} outfile=${grp_name}
group min ${grp_num}
exit !${grp_name}
EOF

        done
    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuHxd_7="_SuzakuHxd_7_fitDirectory"
alias yt_suzakuHxd_fitDirectory="_SuzakuHxd_7_fitDirectory"
function _SuzakuHxd_7_fitDirectory() {
    # to fit directory
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D

    mkdir -p fit $My_Suzaku_D/../fit
    tmp_prefix="hxd_"
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        mkdir $My_Suzaku_D/fit -p
        cp $My_Suzaku_Dir/fit/${tmp_prefix}*.* $My_Suzaku_D/fit/ -f
    done
    find $My_Suzaku_D/fit/ -name "${tmp_prefix}*.*" \
        -type f -printf "%f\n" |
        xargs -n 1 -i rm -f $My_Suzaku_D/../fit/{}
    find -L $My_Suzaku_D/../fit/ -type l -delete
    ln -s $My_Suzaku_D/fit/${tmp_prefix}*.* $My_Suzaku_D/../fit/
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

#!/bin/bash

function _old_SuzakuHxd_2_obtainRspGti() {
    ## set rsp, gti
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

        rsp_index=$(_Obtain_SuzakuHxd_RspIndex ${obs_MJD})
        _rsp_tmps=($(ls $CALDB/data/suzaku/hxd/cpf/ae_hxd_pinhxnome${rsp_index}*.rsp))
        rsp_file=${_rsp_tmps[-1]}
        _rsp_flat_tmps=($(ls $CALDB/data/suzaku/hxd/cpf/ae_hxd_pinflate${rsp_index}*.rsp))
        rsp_flat_file=${_rsp_flat_tmps[-1]}

        rm -f hxd__src.rmf hxd__flat.rmf
        ln -s ${rsp_file} hxd__src.rmf
        ln -s ${rsp_flat_file} hxd__flat.rmf

        ### merge gti
        gti_file=tmp_pin.gti
        rm $gti_file -f &&
            mgtime ingtis="${pin_file}+2,tmp_nxb.evt+2" \
                outgti=$gti_file merge="AND"
    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

function _old_SuzakuHxd_3_xselect() {
    ## extract spec
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat << EOF

${FUNCNAME[1]}
    filter region and extract spectrum


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
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
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

function _old_SuzakuHxd_4_corrections() {
    ## dead time correction and BGD EXPOSURE correction
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat << EOF

${FUNCNAME[1]}
    filter region and extract spectrum


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
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

        cd $My_Suzaku_Dir
        ### dead time correction

        _pse_tmp=($(ls ae${My_Suzaku_ID}hxd_0_pse_cl*.evt*))
        pse_file=${_pse_tmp[0]}

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


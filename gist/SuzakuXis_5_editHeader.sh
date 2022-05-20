# _SuzakuXis_5_editHeader
## edit header
FLAG_minimum=false # arg
FLAG_strict=false # arg
origSrc=nu%OBSID%A01_sr.pha # arg
origBkg=nu%OBSID%A01_bk.pha # arg
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

    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
    if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi
    cd $My_Suzaku_Dir/fit
    find . -type f -regextype posix-egrep -regex "\.\/xis_[A-Z]+[0-9]+__.*\..*" -printf "%f\n" |
        rename -f "s/(xis_[A-Z]+[0-9]+)__/\$1_${My_Suzaku_ID}_/"
    nongrp_names=($(find . -name "xis_*_nongrp.fits" -printf "%f\n"))
    for nongrp_name in ${nongrp_names[@]}; do
        xis_cam_fb=$(echo $nongrp_name | sed -r -n "s/^.*(xis_[A-Z]+[0-9]+)_.*$/\1/p")
        xis_fb=$(echo $xis_cam_fb | sed -r -n "s/^xis_([A-Z]+)[0-9]+$/\1/p")
        if [[ "x${xis_fb}" == "xBI" ]]; then
            nongrpExtNum=$(_ObtainExtNum $nongrp_name SPECTRUM)
            declare -A tr_keys=(
                ["BACKFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_bkg.fits
                ["RESPFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_rmf.fits
                ["ANCRFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_arf.fits)

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile="${nongrp_name}+${nongrpExtNum}" \
                    keyword="${key}" add=yes
            done

        elif
            [[ "x${xis_fb}" == "xFI" ]]
        then

            tmp_fi_num=${xis_cam_fb/xis_FI/}
            fi_num=${tmp_fi_num:0:1}

            oldName=xi${fi_num}__nongrp.fits
            newName=${nongrp_name}
            oldExtNum=$(_ObtainExtNum $oldName SPECTRUM)
            newExtNum=$(_ObtainExtNum $newName SPECTRUM)

            cp_keys=(TELESCOP OBS_MODE DATAMODE OBS_ID OBSERVER OBJECT NOM_PNT RA_OBJ DEC_OBJ
                RA_NOM DEC_NOM PA_NOM MEAN_EA1 MEAN_EA2 MEAN_EA3 RADECSYS EQUINOX DATE-OBS
                DATE-END TSTART TSTOP TELAPSE ONTIME LIVETIME TIMESYS MJDREFI MJDREFF
                TIMEREF TIMEUNIT TASSIGN CLOCKAPP TIMEDEL TIMEPIXR TIERRELA TIERABSO)

            declare -A tr_keys=(
                ["INSTRUME"]="XIS-FI"
                ["BACKFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_bkg.fits
                ["RESPFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_rmf.fits
            )

            for key in ${cp_keys[@]}; do
                orig_val=$(fkeyprint infile="${oldName}+${oldExtNum}" keynam="${key}" |
                    grep "${key}\s*=" |
                    sed -r -n "s/^.*${key}\s*=\s*(.*)\s*\/.*$/\1/p")

                tr_keys[$key]="${orig_val}"
            done

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile="${newName}+${newExtNum}" \
                    keyword="${key}" add=yes
            done

        fi

    done
done

cd $My_Suzaku_D
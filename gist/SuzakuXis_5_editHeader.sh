# _SuzakuXis_5_editHeader
## edit header
FLAG_minimum=false # arg
FLAG_strict=false # arg
origSrc=nu%OBSID%A01_sr.pha # arg
origBkg=nu%OBSID%A01_bk.pha # arg
declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do

    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
    if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi
    cd $My_Suzaku_Dir/fit
    find . -regextype sed -regex "xis_[A-Z]+[0-9]+__*.*" |
        rename -f "s/(xis_[A-Z]+[0-9]+)__/\$1_${My_Suzaku_ID}_/"
    nongrp_names=($(find . -name "xis_*_nongrp.fits" -printf "%f\n"))
    for nongrp_name in ${nongrp_names[@]}; do
        xis_cam_fb=$(echo $nongrp_name | sed -r -n "s/^.*(xis_[A-Z]+[0-9]+)_.*$/\1/p")
        xis_fb=$(echo $xis_cam_fb | sed -r -n "s/^xis_([A-Z]+)[0-9]+$/\1/p")
        if [[ "x${xis_fb}" == "xBI" ]]; then

            declare -A tr_keys=(
                ["BACKFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_bkg.fits
                ["RESPFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_src.rmf
                ["ANCRFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_src.arf)

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile=${nongrp_name}+1 \
                    keyword="${key}" add=yes
            done

        elif
            [[ "x${xis_fb}" == "xFI" ]]
        then

            tmp_fi_num=${xis_cam_fb/xis_FI/}
            fi_num=${tmp_fi_num:0:1}

            oldName=xi${fi_num}__nongrp.fits
            newName=${nongrp_name}

            cp_keys=(TELESCOP OBS_MODE DATAMODE OBS_ID OBSERVER OBJECT NOM_PNT RA_OBJ DEC_OBJ
                RA_NOM DEC_NOM PA_NOM MEAN_EA1 MEAN_EA2 MEAN_EA3 RADECSYS EQUINOX DATE-OBS
                DATE-END TSTART TSTOP TELAPSE ONTIME LIVETIME TIMESYS MJDREFI MJDREFF
                TIMEREF TIMEUNIT TASSIGN CLOCKAPP TIMEDEL TIMEPIXR TIERRELA TIERABSO)

            declare -A tr_keys=(
                ["INSTRUME"]="XIS-FI"
                ["BACKFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_bkg.fits
                ["RESPFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_src.rmf
            )

            for key in ${cp_keys[@]}; do
                orig_val=$(fkeyprint infile="${oldName}+0" keynam="${key}" |
                    grep "${key}\s*=" |
                    sed -r -n "s/^.*${key}\s*=\s*(.*)\s*\/.*$/\1/p")

                tr_keys[$key]="${orig_val}"
            done

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile=${newName}+1 \
                    keyword="${key}" add=yes
            done

        fi

    done
done

cd $My_Suzaku_D
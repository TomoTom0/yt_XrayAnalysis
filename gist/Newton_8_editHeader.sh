# _Newton_8_editHeader
## edit header
FLAG_minimum=false # arg
FLAG_strict=false # arg
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
cd $My_Newton_D

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
for My_Newton_ID in ${obs_dirs[@]}; do
    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
    cd $My_Newton_Dir/fit

    all_cams_tmp2=($(find . -name "newton_*_nongrp.fits" -printf "%f\n" |
        sed -r -n "s/^newton_(mos1|mos2|mos12|pn)_${My_Newton_ID}_nongrp.fits$/\1/p"))
    for cam in ${all_cams_tmp2[@]}; do
        nongrp_name=newton_${cam}_${My_Newton_ID}_nongrp.fits
        if [[ $cam == "mos12" ]]; then
            # edit header for nongrp
            oldName=newton_mos1_${My_Newton_ID}_nongrp.fits
            newName=$nongrp_name
            oldExtNum=$(_ObtainExtNum $oldName SPECTRUM)
            newExtNum=$(_ObtainExtNum $newName SPECTRUM)


            cp_keys=(LONGSTRN DATAMODE TELESCOP OBS_ID OBS_MODE REVOLUT
                OBJECT OBSERVER RA_OBJ DEC_OBJ RA_NOM DEC_NOM FILTER ATT_SRC
                ORB_RCNS TFIT_RPD TFIT_DEG TFIT_RMS TFIT_PFR TFIT_IGH SUBMODE
                EQUINOX RADECSYS REFXCTYP REFXCRPX REFXCRVL REFXCDLT REFXLMIN
                REFXLMAX REFXCUNI REFYCTYP REFYCRPX REFYCRVL REFYCDLT
                REFYLMIN REFYLMAX REFYCUNI AVRG_PNT RA_PNT DEC_PNT PA_PNT)

            cp_keys2=(DATE-OBS DATE-END)

            declare -A tr_keys=(
                ["INSTRUME"]="EMOS1+EMOS2"
                ["BACKFILE"]=newton_${cam}_${My_Newton_ID}_bkg.fits
                ["RESPFILE"]=newton_${cam}_${My_Newton_ID}_rmf.fits
            )
            if [[ ${FLAG_strict:=false} == "true" ]]; then
                cp_keys2=()
            fi
            if [[ ${FLAG_minimum:=false} == "true" ]]; then
                cp_keys=()
                cp_keys2=()
            fi

            for key in ${cp_keys[@]} ${cp_keys2[@]}; do
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

        else
            # for pn, mos1, mos2
            nongrpExtNum=$(_ObtainExtNum $nongrpName SPECTRUM)
            declare -A tr_keys=(
                ["BACKFILE"]=newton_${cam}_${My_Newton_ID}_bkg.fits
                ["RESPFILE"]=newton_${cam}_${My_Newton_ID}_rmf.fits
                ["ANCRFILE"]=newton_${cam}_${My_Newton_ID}_arf.fits)

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile="${nongrp_name}+${nongrpExtNum}" \
                    keyword="${key}" add=yes
            done
        fi

    done
done

cd $My_Newton_D

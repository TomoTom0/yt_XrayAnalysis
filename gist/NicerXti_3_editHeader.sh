# _NicerXti_3_editHeader
## edit header
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
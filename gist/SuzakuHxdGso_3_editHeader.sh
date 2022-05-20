# _SuzakuHxdGso_3_editHeader
## edit header
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
    if [[ ! -r $My_Suzaku_Dir/fitGso ]]; then continue; fi

    cd $My_Suzaku_Dir/fitGso
    find . -name "hxdGso__*" | rename -f "s/hxdGso__/hxdGso_${My_Suzaku_ID}_/"
    for nongrp_name in $(find . -name "hxdGso_[0-9]*_nongrp.fits" -printf "%f\n"); do
        grp_name=${nongrp_name/_nongrp.fits/_grp${grp_num}.fits}
        nongrpExtNum=$(_ObtainExtNum $nongrp_name SPECTRUM)
        declare -A tr_keys=(
            ["RESPFILE"]=hxdGso_${My_Suzaku_ID}_rmf.fits
            ["BACKFILE"]=hxdGso_${My_Suzaku_ID}_bkg.fits
            ["ANCRFILE"]=hxdGso_${My_Suzaku_ID}_arf.fits)

        for key in ${!tr_keys[@]}; do
            fparkey value="${tr_keys[$key]}" \
                fitsfile="${nongrp_name}+${nongrpExtNum}" \
                keyword="${key}" add=yes
        done

    done

done
cd $My_Suzaku_D
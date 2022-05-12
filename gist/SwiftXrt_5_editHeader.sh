# _SwiftXrt_5_editHeader
## edit header
declare -g My_Swift_D=${My_Swift_D:=$(pwd)} # 未定義時に代入
cd $My_Swift_D
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
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir/xrt/output/fit ]]; then continue; fi

    cd $My_Swift_Dir/xrt/output/fit

    find . -name "xrt__*" |
        rename -f "s/xrt__/xrt_${My_Swift_ID}_/"

    nongrp_name=xrt_${My_Swift_ID}_nongrp.fits
    nongrpExtNum=$(_ObtainExtNum $nongrp_name SPECTRUM)

    declare -A tr_keys=(
        ["BACKFILE"]=xrt_${My_Swift_ID}_bkg.fits
        ["RESPFILE"]=xrt_${My_Swift_ID}_rmf.fits
        ["ANCRFILE"]=xrt_${My_Swift_ID}_arf.fits)

    for key in ${!tr_keys[@]}; do
        fparkey value="${tr_keys[$key]}" \
            fitsfile="${nongrp_name}+${nongrpExtNum}" \
            keyword="${key}" add=yes
    done

done

cd $My_Swift_D
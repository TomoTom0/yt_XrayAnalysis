# _SwiftXrtBuild_3_grppha
## grppha
gnum=10 # arg
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Swift_D=${My_Swift_D:=$(pwd)} 
else 
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
fi
cd $My_Swift_D/xrt
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
    #echo ${_tmp_extNums[0]:-0}
}
prod_IDs=($(find . -maxdepth 1 -type d -printf "%P\n" |
    grep ^xrt_build_[0-9] |
    sed -r -n "s/^xrt_build_([0-9]+)$/\1/p"))
for prod_ID in ${prod_IDs[@]}; do
    spec_path=$My_Swift_D/xrt/xrt_build_${prod_ID}/spec
    if [[ ! -r $spec_path ]]; then continue; fi
    cd $spec_path/fit

    nongrp_names=($(find . -name "xrtBuild*_nongrp.fits" -printf "%f\n"))
    for nongrp_name in ${nongrp_names[@]}; do
        tmp_head=${nongrp_name/_nongrp.fits/}
        grpAuto_name=${tmp_head}_grpauto.fits
        nongrpExtNum=$(_ObtainExtNum $nongrp_name SPECTRUM)
        grpAutoExtNum=$(_ObtainExtNum $grpAuto_name SPECTRUM)

        declare -A tr_keys=(
            ["BACKFILE"]=${tmp_head}_bkg.fits
            ["RESPFILE"]=${tmp_head}_rmf.fits
            ["ANCRFILE"]=${tmp_head}_arf.fits)

        for key in ${!tr_keys[@]}; do
            fparkey value="${tr_keys[$key]}" \
                fitsfile="${nongrp_name}+${nongrpExtNum}" \
                keyword="${key}" add=yes
        done

        for key in ${!tr_keys[@]}; do
            fparkey value="${tr_keys[$key]}" \
                fitsfile="${grpAuto_name}+${grpAutoExtNum}" \
                keyword="${key}" add=yes
        done
        if [[ $gnum -le 0 ]]; then continue; fi
        for gnum_tmp in $gnum 1; do
            grp_name=${tmp_head}_grp${gnum_tmp}.fits
            cat <<EOF | bash
grppha infile=$nongrp_name outfile=$grp_name
group min $gnum_tmp
exit !$grp_name
EOF
        done

    done
done
cd $My_Swift_D
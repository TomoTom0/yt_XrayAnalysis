# _SwiftXrt_5_editHEader
## edit header
echo ${My_Swift_D:=$(pwd)} # 未定義時に代入
cd $My_Swift_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir/xrt/output/fit ]]; then continue; fi

    cd $My_Swift_Dir/xrt/output/fit

    find . -name "xrt__*" |
        rename "s/xrt__/xrt_${My_Swift_ID}_/" -f

    nongrp_name=xrt_${My_Swift_ID}_nongrp.fits

    declare -A tr_keys=(
        ["BACKFILE"]=xrt_${My_Swift_ID}_bkg.fits
        ["RESPFILE"]=xrt_${My_Swift_ID}_rmf.fits
        ["ANCRFILE"]=xrt_${My_Swift_ID}_arf.fits)

    for key in ${!tr_keys[@]}; do
        fparkey value="${tr_keys[$key]}" \
            fitsfile=${nongrp_name}+1 \
            keyword="${key}" add=yes
    done

done

cd $My_Swift_D
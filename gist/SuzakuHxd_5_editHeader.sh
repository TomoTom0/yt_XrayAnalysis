# _SuzakuHxd_5_editHeader
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
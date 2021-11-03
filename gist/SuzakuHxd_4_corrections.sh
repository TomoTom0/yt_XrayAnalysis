# _SuzakuHxd_4_corrections
## dead time correction and BGD EXPOSURE correction
echo ${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D
for My_Suzaku_ID in ${obs_dirs[@]}; do
    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
    if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

    cd $My_Suzaku_Dir
    ### dead time correction

    pse_file_tmp=($(ls ae${My_Suzaku_ID}hxd_0_pse_cl*.evt*))
    pse_file=${pse_file_tmp[0]}

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

# _SuzakuHxd_3_xselect
## extract spec
echo ${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D
for My_Suzaku_ID in ${obs_dirs[@]}; do
    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
    if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

    cd $My_Suzaku_Dir
    _pin_tmps=($(ls ae${My_Suzaku_ID}hxd_0_pinno_cl*.evt*))
    pin_file=${_pin_tmps[0]}
    gti_file=tmp_pin.gti

    rm tmp_hxd_src.pha tmp_hxd_nxb.pha -f
    cat <<EOF | bash
xselect
xsel
read event ${pin_file}
./
filter time file $gti_file
set PHANAME PI_PIN
extract spec
save spec tmp_hxd_nongrp.fits
read event tmp_nxb.evt
filter time file $gti_file
set PHANAME PI_PIN
extract spec
save spec tmp_hxd_nxb.fits
exit
n
EOF
done
cd $My_Suzaku_D
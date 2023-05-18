# _NicerXti_1_products
## xti products
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then
    My_Nicer_D=${My_Nicer_D:=$(pwd)}
else
    declare -g My_Nicer_D=${My_Nicer_D:=$(pwd)}
fi # 未定義時に代入
cd $My_Nicer_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
for My_Nicer_ID in ${obs_dirs[@]}; do

    My_Nicer_Dir=$My_Nicer_D/$My_Nicer_ID
    if [[ ! -r $My_Nicer_Dir/xti/event_cl ]]; then continue; fi

    cd $My_Nicer_Dir/xti/event_cl

    _evt_tmps=($(find . -name "ni${My_Nicer_ID}_0mpu7_cl.evt*" -printf "%f\n"))
    evt_file=${_evt_tmps[-1]}

    rm -f nicerXti__*.fits
    cat <<EOF | bash
xselect
xsel
read events ${evt_file}
./
y
extract all
extract spectrum
save spectrum nicerXti__nongrp.fits
exit
n
EOF

    # arf, rmfをcopy
    _arf_files=($(find $CALDB/data/nicer/xti/cpf/arf/ -name "*.arf"))
    _rmf_files=($(find $CALDB/data/nicer/xti/cpf/rmf/ -name "*.rmf"))
    cp -f ${_arf_files[-1]} nicerXti__arf.fits
    cp -f ${_rmf_files[-1]} nicerXti__rmf.fits

    mkdir fit -p
    mv nicerXti__*.fits fit/

done
cd $My_Nicer_D
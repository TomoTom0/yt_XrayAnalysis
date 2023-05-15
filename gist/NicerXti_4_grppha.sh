# _NicerXti_4_grppha
## grppha
gnum=50 # arg
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then
    My_Nicer_D=${My_Nicer_D:=$(pwd)}
else
    declare -g My_Nicer_D=${My_Nicer_D:=$(pwd)}
fi # 未定義時に代入
cd $My_Nicer_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
for My_Nicer_ID in ${obs_dirs[@]}; do

    My_Nicer_Dir=$My_Nicer_D/$My_Nicer_ID
    if [[ ! -r $My_Nicer_Dir/xti/event_cl/fit ]]; then continue; fi

    cd $My_Nicer_Dir/xti/event_cl/fit
    nongrp_name=nicerXti_${My_Nicer_ID}_nongrp.fits
    grp_name=nicerXti_${My_Nicer_ID}_grp${gnum}.fits
    rm $grp_name -f
    cat <<EOF | bash
grppha infile=$nongrp_name outfile=$grp_name
group min ${gnum}
exit !$grp_name
EOF

done
cd $My_Nicer_D
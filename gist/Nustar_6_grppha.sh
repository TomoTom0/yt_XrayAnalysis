# _Nustar_6_grppha
## grppha
gnum=50 # arg
declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} # 未定義時に代入
cd $My_Nustar_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir/fit ]]; then continue; fi
    cd $My_Nustar_Dir/fit/
    if [[ ${gnum} -le 0 ]]; then continue; fi
    grp_name=AB_${My_Nustar_ID}_grp${gnum}.fits
    rm ${grp_name} -f
    cat <<EOF | bash
grppha infile=AB_${My_Nustar_ID}_nongrp.fits outfile=${grp_name} clobber=true
group min ${gnum}
exit !${grp_name}
EOF
done
cd $My_Nustar_D
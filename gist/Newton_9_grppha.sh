# _Newton_9_grppha
## grppha
declare -A gnums=(["pn"]=50 ["mos12"]=50 ["mos1"]=30 ["mos2"]=30) # arg
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
cd $My_Newton_D

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do
    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
    cd $My_Newton_Dir/fit

    all_cams_tmp2=($(find . -name "newton_*_nongrp.fits" -printf "%f\n" |
        sed -r -n "s/^newton_(mos1|mos2|mos12|pn)_${My_Newton_ID}_nongrp.fits$/\1/p"))
    for cam in ${all_cams_tmp2[@]}; do
        gnum=${gnums[$cam]}
        if [[ $gnum -le 0 ]]; then continue; fi
        grp_name=newton_${cam}_${My_Newton_ID}_grp${gnum}.fits
        nongrp_name=newton_${cam}_${My_Newton_ID}_nongrp.fits
        cat <<EOF | bash
grppha infile=$nongrp_name outfile=${grp_name}
group min ${gnum}
exit !${grp_name}
EOF
    done
done

cd $My_Newton_D

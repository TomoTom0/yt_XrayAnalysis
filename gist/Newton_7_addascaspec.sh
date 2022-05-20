# _Newton_7_addascaspec
## addascaspec
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
cd $My_Newton_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do

    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
    cd $My_Newton_Dir/fit

    all_cams_now=($(find . -name "*_nongrp.fits" -printf "%f\n" | sed -r -n "s/^.*(mos1|mos2|pn)_.*_nongrp.fits$/\1/p"))
    for cam in ${all_cams_now[@]}; do
        find . -name "${cam}__*.fits" -printf "%f\n" |
            rename -f "s/^${cam}__/newton_${cam}_${My_Newton_ID}_/"
    done

    if [[ " ${all_cams_now[@]} " =~ " mos1 " && " ${all_cams_now[@]} " =~ " mos2 " ]]; then
        mos_cams=($(echo ${all_cams_now[@]//pn/} | sed -r -n "s/\s*(mos1|mos2)\s*/\1 /gp"))
        : >tmp_fi.add
        echo ${mos_cams[@]} | sed -r "s/\s*(mos1|mos2)\s*/newton_\1_${My_Newton_ID}_nongrp.fits /g" >>tmp_fi.add
        echo ${mos_cams[@]} | sed -r "s/\s*(mos1|mos2)\s*/newton_\1_${My_Newton_ID}_bkg.fits /g" >>tmp_fi.add
        echo ${mos_cams[@]} | sed -r "s/\s*(mos1|mos2)\s*/newton_\1_${My_Newton_ID}_rmf.fits /g" >>tmp_fi.add
        echo ${mos_cams[@]} | sed -r "s/\s*(mos1|mos2)\s*/newton_\1_${My_Newton_ID}_arf.fits /g" >>tmp_fi.add

        rm -f newton_mos12_${My_Newton_ID}_nongrp.fits \
            newton_mos12_${My_Newton_ID}_rmf.fits newton_mos12_${My_Newton_ID}_bkg.fits
        addascaspec tmp_fi.add newton_mos12_${My_Newton_ID}_nongrp.fits \
            newton_mos12_${My_Newton_ID}_rmf.fits newton_mos12_${My_Newton_ID}_bkg.fits
    fi
done

cd $My_Newton_D
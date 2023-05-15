# _SuzakuXis_4_addascaspec
## addascaspec
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
else 
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
fi
cd $My_Suzaku_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do

    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
    if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi
    cd $My_Suzaku_Dir/fit
    xis_cams=($(ls xi[0-3]__nongrp.fits | sed -r -n "s/^.*(xi[0-3])__.*$/\1/p"))
    xis_cams_fi=(${xis_cams[@]//xi1/})
    if [[ ${#xis_cams_fi[@]} -ge 1 ]]; then
        cat <<EOF >tmp.dat
$(echo ${xis_cams_fi[@]} | sed -r "s/(xi[0-9])\s*/\1__nongrp.fits /g")
$(echo ${xis_cams_fi[@]} | sed -r "s/(xi[0-9])\s*/\1__bkg.fits /g")
$(echo ${xis_cams_fi[@]} | sed -r "s/(xi[0-9])\s*/\1__arf.fits /g")
$(echo ${xis_cams_fi[@]} | sed -r "s/(xi[0-9])\s*/\1__rmf.fits /g")
EOF

        xis_cams_fi_sum=($(echo ${xis_cams_fi[@]} | sed -r -n "s/xi([0-9])\s*/\1/p"))
        fi_head=xis_FI$(echo ${xis_cams_fi_sum[@]} | sed -e "s/xi//g" -e "s/ //g")
        rm ${fi_head}__nongrp.fits ${fi_head}__bkg.fits ${fi_head}__rmf.fits -f
        addascaspec tmp.dat ${fi_head}__nongrp.fits ${fi_head}__rmf.fits ${fi_head}__bkg.fits
    fi

    xis_cams_bi=($(echo ${xis_cams[@]} | grep xi1 -o))
    if [[ ${#xis_cams_bi[@]} -ge 1 ]]; then
        xis_cam=${xis_cams_bi[0]}
        bi_head=xis_BI${xis_cam/xi/}
        ls ${xis_cam}__* | sed "p;s/${xis_cam}__/${bi_head}__/g" | xargs -n 2 cp
    fi
done
cd $My_Suzaku_D
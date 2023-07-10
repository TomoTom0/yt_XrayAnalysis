# _Nustar_4_addascaspec
## addascaspec
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Nustar_D=${My_Nustar_D:=$(pwd)} 
else 
    declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} 
fi # 未定義時に代入
cd $My_Nustar_D
fitsName_head="nustar_AB_"
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir/fit ]]; then continue; fi

    cd $My_Nustar_Dir/fit

    cat <<EOF >tmp_fi.add
nu${My_Nustar_ID}A01_sr.pha nu${My_Nustar_ID}B01_sr.pha
nu${My_Nustar_ID}A01_bk.pha nu${My_Nustar_ID}B01_bk.pha
nu${My_Nustar_ID}A01_sr.arf nu${My_Nustar_ID}B01_sr.arf
nu${My_Nustar_ID}A01_sr.rmf nu${My_Nustar_ID}B01_sr.rmf
EOF

    rm ${fitsName_head}${My_Nustar_ID}_nongrp.fits \
        ${fitsName_head}${My_Nustar_ID}_rsp.fits \
        ${fitsName_head}${My_Nustar_ID}_bkg.fits -f
    addascaspec tmp_fi.add \
        ${fitsName_head}${My_Nustar_ID}_nongrp.fits \
        ${fitsName_head}${My_Nustar_ID}_rsp.fits \
        ${fitsName_head}${My_Nustar_ID}_bkg.fits
done
cd $My_Nustar_D
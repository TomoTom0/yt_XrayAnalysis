# _Newton_7_addascaspec
## addascaspec
echo ${My_Newton_D:=$(pwd)}
cd $My_Newton_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do

    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
    cd $My_Newton_Dir/fit

    all_cams_now=($(ls *_nongrp.fits | sed -r -n "s/^.*(mos1|mos2|pn)_.*_nongrp.fits$/\1/p"))
    for cam in ${all_cams_now[@]}; do
        find . -name "${cam}__*.fits" |
            rename "s/^${cam}__/newton_${cam}_${My_Newton_ID}_/" -f
    done

    if [[ -n $(echo ${all_cams_now} | grep mos) ]]; then
        mos_cams=($(echo ${all_cams_now[@]//pn/} | sed -r -n "s/\s*(mos1|mos2)\s*/\1 /gp"))
        cat <<EOF >tmp_fi.add
$(for mos_cam in ${mos_cams[@]}; do echo "newton_${mos_cam}_${My_Newton_ID}_pi.fits "; done)
$(for mos_cam in ${mos_cams[@]}; do echo "newton_${mos_cam}_${My_Newton_ID}_bkg.fits "; done)
$(for mos_cam in ${mos_cams[@]}; do echo "newton_${mos_cam}_${My_Newton_ID}_rmf.fits "; done)
$(for mos_cam in ${mos_cams[@]}; do echo "newton_${mos_cam}_${My_Newton_ID}_arf.fits "; done)
EOF
        rm -f newton_mos12_${My_Newton_ID}_nongrp.fits \
            newton_mos12_${My_Newton_ID}_rmf.fits newton_mos12_${My_Newton_ID}_bkg.fits
        addascaspec tmp_fi.add newton_mos12_${My_Newton_ID}_nongrp.fits \
            newton_mos12_${My_Newton_ID}_rmf.fits newton_mos12_${My_Newton_ID}_bkg.fits
    fi
done

cd $My_Newton_D
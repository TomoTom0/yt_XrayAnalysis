# _Newton_6_genRmfArf
## rmf, arf作成
FLAG_rmf=true # arg
FLAG_arf=true # arg
declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
cd $My_Newton_D

if [[ x == x$(alias sas 2>/dev/null) ]]; then
    echo "Error: alias sas is not defined."
    kill -INT $$
fi
sas
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do
    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
    cd $My_Newton_Dir/fit
    all_cams_now=($(find . -name "*__nongrp.fits" -printf "%f\n" |
        sed -r -n "s/^(mos1|mos2|pn)__nongrp.fits$/\1/p"))

    for cam in ${all_cams_now[@]}; do
        rm ${cam}__rmf.fits ${cam}__arf.fits -f
        export SAS_CCF=$My_Newton_Dir/ccf.cif
        if [[ "${FLAG_rmf:=true}" == "true" ]]; then
            rm ${cam}__rmf.fits -f &&
                rmfgen rmfset=${cam}__rmf.fits spectrumset=${cam}__nongrp.fits
        fi
        if [[ "${FLAG_arf:=true}" == "true" ]]; then
            rm ${cam}__arf.fits -f &&
                arfgen arfset=${cam}__arf.fits spectrumset=${cam}__nongrp.fits \
                withrmfset=yes rmfset=${cam}__rmf.fits withbadpixcorr=yes \
                badpixlocation=${cam}_filt_time.fits
        fi
    done
done
cd $My_Newton_D

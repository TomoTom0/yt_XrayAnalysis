# _Newton_6_genRmfArf
## rmf, arf作成
FLAG_rmf=true # arg
FLAG_arf=true # arg
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
cd $My_Newton_D

if [[ x == "x$(alias sas 2>/dev/null)" ]]; then
    echo "Error: alias sas is not defined."
    kill -INT $$
fi
sas
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do
    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
    cd $My_Newton_Dir/fit
    all_cams_now=($(find . -name "*_nongrp.fits" -printf "%f\n" |
        sed -r -n "s/^.*(mos1|mos2|pn).*_nongrp.fits$/\1/p"))

    for cam in ${all_cams_now[@]}; do
        rm ${cam}__rmf.fits ${cam}__arf.fits -f
        export SAS_CCF=$My_Newton_Dir/ccf.cif
        if [[ ! -r "${SAS_CCF}" ]]; then continue ; fi
        #_nongrp_tmps=($(find . -name "*${cam}*_nongrp.fits" -printf "%f\n"))
        #if [[ ${_nongrp_tmps[@]} -eq 0 ]]; then continue; fi
        #nongrp_name=${_nongrp_tmps[0]}
        nongrp_name=${cam}__nongrp.fits
        if [[ "${FLAG_rmf:=true}" == "true" ]]; then
            rm ${cam}__rmf.fits -f &&
                rmfgen rmfset=${cam}__rmf.fits spectrumset=${nongrp_name}
        fi
        if [[ "${FLAG_arf:=true}" == "true" ]]; then
            #_rmf_tmps=($(find . -name "*${cam}*_rmf.fits" -printf "%f\n"))
            #if [[ ${_rmf_tmps[@]} -eq 0 ]]; then continue; fi
            #rmf_name=${_rmf_tmps[0]}
            rmf_name=${cam}__rmf.fits
            rm ${cam}__arf.fits -f &&
                arfgen arfset=${cam}__arf.fits spectrumset=${nongrp_name} \
                    withrmfset=yes rmfset=${rmf_name} withbadpixcorr=yes \
                    badpixlocation=${cam}_filt_time.fits
        fi
    done
done
cd $My_Newton_D

# _SuzakuXis_6_grppha
## grppha
declare -A gnums=(["FI"]=25 ["BI"]=25) # arg
declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do

    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
    if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi
    cd $My_Suzaku_Dir/fit
    nongrp_names=($(find . -name "xis_*_nongrp.fits" -printf "%f\n"))
    for nongrp_name in ${nongrp_names[@]}; do
        xis_cam_fb=$(echo $nongrp_name | sed -r -n "s/^.*(xis_[A-Z]+[0-9]+)_.*$/\1/p")
        xis_fb=$(echo $xis_cam_fb | sed -r -n "s/^xis_([A-Z]+)[0-9]+$/\1/p")
        gnum=${gnums[$xis_fb]}
        grp_name=${nongrp_name/_nongrp.fits/_grp${gnum}.fits}

        rm $grp_name -f

        cat <<EOF | bash
grppha infile=$nongrp_name \
outfile=$grp_name
group min $gnum
exit !$grp_name
EOF
    done

done
cd $My_Suzaku_D
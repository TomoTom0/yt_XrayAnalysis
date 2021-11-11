# _SuzakuHxdPin_4_grppha
## grppha
gnum=25 # arg
declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do
    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
    if [[ ! -r $My_Suzaku_Dir/fitPin ]]; then continue; fi

    cd $My_Suzaku_Dir/fitPin
    for nongrp_name in $(find . -name "hxdPin_[0-9]*_nongrp.fits" -printf "%f\n"); do
        grp_name=${nongrp_name/_nongrp.fits/_grp${gnum}.fits}

        rm $grp_name -f
        cat <<EOF | bash
grppha infile=${nongrp_name} outfile=${grp_name}
group min ${gnum}
exit !${grp_name}
EOF

    done
done
cd $My_Suzaku_D
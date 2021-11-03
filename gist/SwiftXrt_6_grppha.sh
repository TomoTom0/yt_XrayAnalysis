# _SwiftXrt_6_grppha
## grppha
gnum=50 # arg
declare -g My_Swift_D=${My_Swift_D:=$(pwd)} # 未定義時に代入
cd $My_Swift_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir/xrt/output/fit/ ]]; then continue; fi

    cd $My_Swift_Dir/xrt/output/fit/
    nongrp_name=xrt_${My_Swift_ID}_nongrp.fits
    grp_name=xrt_${My_Swift_ID}_grp${gnum}.fits
    rm $grp_name -f
    cat <<EOF | bash
grppha infile=$nongrp_name outfile=$grp_name
group min ${gnum}
exit !$grp_name

EOF

done
cd $My_Swift_D
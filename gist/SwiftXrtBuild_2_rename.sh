# _SwiftXrtBuild_2_rename
## rename and make symbolic link
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Swift_D=${My_Swift_D:=$(pwd)} 
else 
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
fi
cd $My_Swift_D/xrt
## make symbolic link
prod_IDs=($(find . -maxdepth 1 -type d -printf "%P\n" |
    grep ^xrt_build_[0-9] |
    sed -r -n "s/^xrt_build_([0-9]+)$/\1/p"))
for prod_ID in ${prod_IDs[@]}; do
    build_path=$My_Swift_D/xrt/xrt_build_${prod_ID}
    spec_path=$build_path/spec
    #### already exists -> continue
    if [[ -r $spec_path ]]; then continue; fi
    #### not exist
    cd $build_path
    if [[ -d "USERPROD_${prod_ID}" ]]; then
        rm $spec_path -f &&
            ln -s $build_path/USERPROD_${prod_ID}/spec $spec_path
    elif [[ x$(find ./ -regex ".*\(pc\|wt\)\.pi" -printf "1") != x ]]; then
        rm $spec_path -f &&
            ln -s $build_path $spec_path
    fi
done
cd $My_Swift_D/

### edit Header
cd $My_Swift_D/xrt
prod_IDs=($(find . -maxdepth 1 -type d -printf "%P\n" |
    grep ^xrt_build_[0-9] |
    sed -r -n "s/^xrt_build_([0-9]+)$/\1/p"))
for prod_ID in ${prod_IDs[@]}; do
    spec_path=$My_Swift_D/xrt/xrt_build_${prod_ID}/spec
    if [[ ! -r $spec_path ]]; then continue; fi
    cd $spec_path

    rm $spec_path/fit -rf
    mkdir $spec_path/fit -p

    # for per Obs
    obs_IDs=($(find . -name "Obs_*[pw][ct].pi" -printf "%f\n" |
        sed -r -n "s/^\S*Obs_([0-9]+)(pc|wt)\S*$/\1/p" | uniq))
    # for per project
    #proj_IDs=($(find . -name "[0-9]*[pw][ct].pi" -printf "%f\n" |
    #    sed -r -n "s/^([0-9]+)(pc|wt)\S*$/\1/p"))
    # for time_averaged
    proj_IDs=($(find . -regex ".+[pw][ct].pi" -printf "%f\n" |
        sed -r -n "s/^(.+)(pc|wt)\S*$/\1/p" | uniq))
    if [[ ${#obs_IDs[@]} -ge 1 ]]; then
        for obs_ID in ${obs_IDs[@]}; do
            tmp_head=Obs_${obs_ID}
            for cam in "pc" "wt"; do
                declare -A tmp_orig_names=(
                    ["${cam}_nongrp"]=${tmp_head}${cam}source.pi
                    ["${cam}_grpauto"]=${tmp_head}${cam}.pi
                    ["${cam}_bkg"]=${tmp_head}${cam}back.pi
                    ["${cam}_rmf"]=${tmp_head}${cam}.rmf
                    ["${cam}_arf"]=${tmp_head}${cam}.arf)

                for key in ${!tmp_orig_names[@]}; do
                    orig_name=${tmp_orig_names[$key]}
                    if [[ ! -f "$orig_name" ]]; then continue; fi
                    new_name=xrtBuild${prod_ID}_Obs${obs_ID}_${key}.fits
                    new_names[$key]=$new_name
                    cp -f $orig_name $spec_path/fit/$new_name
                done
            done
        done
    elif [[ ${#proj_IDs[@]} -ge 1  ]]; then
        for proj_ID in ${proj_IDs[@]}; do
            tmp_head=${proj_ID}
            for cam in "pc" "wt"; do
                declare -A tmp_orig_names=(
                    ["${cam}_nongrp"]=${tmp_head}${cam}source.pi
                    ["${cam}_grpauto"]=${tmp_head}${cam}.pi
                    ["${cam}_bkg"]=${tmp_head}${cam}back.pi
                    ["${cam}_rmf"]=${tmp_head}${cam}.rmf
                    ["${cam}_arf"]=${tmp_head}${cam}.arf)

                for key in ${!tmp_orig_names[@]}; do
                    orig_name=${tmp_orig_names[$key]}
                    if [[ ! -f "$orig_name" ]]; then continue; fi
                    new_name=xrtBuild${prod_ID}_Proj${proj_ID}_${key}.fits
                    new_names[$key]=$new_name
                    cp -f $orig_name $spec_path/fit/$new_name
                done
            done
        done
    fi
done
cd $My_Swift_D
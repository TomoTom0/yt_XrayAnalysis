# _SuzakuXis_2_xselect
## extarct spec with xselect
echo ${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do

    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
    if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

    cd $My_Suzaku_Dir
    rm ${My_Suzaku_Dir}/fit -rf
    mkdir ${My_Suzaku_Dir}/fit -p

    ### obtain all xis cameras
    xis_cams_tmp=($(ls ae${My_Suzaku_ID}xi[0-9]_[0-9]_[0-9]x[0-9]*.evt* |
        sed -r -n "s/^.*(xi[0-9]).*$/\1/p"))
    declare -A arr_tmp
    for cam in "${xis_cams_tmp[@]}"; do arr_tmp[$cam]=""; done
    xis_cams=("${!arr_tmp[@]}")

    for xis_cam in ${xis_cams[@]}; do
        evt_files=($(find . -name "ae${My_Suzaku_ID}${xis_cam}_*.evt*" -printf "%f\n"))
        rm gti.txt bkg.pha src.pi evt.file -f
        if [[ ${#evt_files[@]} == 0 ]]; then
            continue
        elif [[ ${#evt_files[@]} == 1 ]]; then
            evt_file=${evt_files[0]}

            cat <<EOF | bash
xselect
xsel
read event ${evt_file}
./
extract all
filter region src.reg
extract spectrum
save spectrum src.pi
n
clear region
filter region bkg.reg
extract spectrum
save spectrum bkg.pha
n
exit
n
EOF

        else

            evt_first=${evt_files[0]}
            evt_others=$(echo ${evt_files[@]:1} | sed -r "s/(\S+)\s*/read event \1\n/g")
            cat <<EOF | bash
xselect
xsel
read event ${evt_first}
./
${evt_others}
extract all
filter region src.reg
extract spectrum
save spectrum src.pi
n
clear region
filter region bkg.reg
extract spectrum
save spectrum bkg.pha
n
exit
n
EOF
        fi
        mv src.pi ${My_Suzaku_Dir}/fit/${xis_cam}__nongrp.fits -f
        mv bkg.pha ${My_Suzaku_Dir}/fit/${xis_cam}__bkg.fits -f
    done
    cp *.reg ${My_Suzaku_Dir}/fit -f
done

cd $My_Suzaku_D
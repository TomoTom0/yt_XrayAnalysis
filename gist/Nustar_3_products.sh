# _Nustar_3_products
## nuproducts
    declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} 
fi # 未定義時に代入
cd $My_Nustar_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir ]]; then continue; fi

    cd $My_Nustar_Dir

    rm $My_Nustar_Dir/fit/* -rf &&
        mkdir $My_Nustar_Dir/fit -p
    for cam in A B; do
        nuproducts \
            srcregionfile=$My_Nustar_Dir/out/src${cam}.reg \
            bkgregionfile=$My_Nustar_Dir/out/bkg${cam}.reg \
            indir=$My_Nustar_Dir/out \
            outdir=$My_Nustar_Dir/fit \
            instrument=FPM${cam} \
            steminputs=nu${My_Nustar_ID} \
            bkgextract=yes \
            clobber=yes
    done

done
cd $My_Nustar_D
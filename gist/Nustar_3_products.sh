# _Nustar_3_products
## nuproducts
echo ${My_Nustar_D:=$(pwd)} # 未定義時に代入
cd $My_Nustar_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir ]]; then continue; fi

    cd $My_Nustar_Dir

    rm $My_Nustar_Dir/fit/* -f
    nuproducts \
        srcregionfile=$My_Nustar_Dir/out/srcA.reg \
        bkgregionfile=$My_Nustar_Dir/out/bkgA.reg \
        indir=$My_Nustar_Dir/out \
        outdir=$My_Nustar_Dir/fit \
        instrument=FPMA \
        steminputs=nu${My_Nustar_ID} \
        bkgextract=yes \
        clobber=yes

    nuproducts \
        srcregionfile=$My_Nustar_Dir/out/srcB.reg \
        bkgregionfile=$My_Nustar_Dir/out/bkgB.reg \
        indir=$My_Nustar_Dir/out \
        outdir=$My_Nustar_Dir/fit \
        instrument=FPMB \
        steminputs=nu${My_Nustar_ID} \
        bkgextract=yes \
        clobber=yes

done
cd $My_Nustar_D
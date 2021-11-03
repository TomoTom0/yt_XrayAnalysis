# _Nustar_1_pipeline
## pipeline
echo ${My_Nustar_D:=$(pwd)}
cd $My_Nustar_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir ]]; then continue; fi

    cd $My_Nustar_Dir

    rm -r -f $My_Nustar_Dir/out
    nupipeline indir=$My_Nustar_Dir \
        steminputs="nu$My_Nustar_ID" \
        outdir="$My_Nustar_Dir/out" saacalc="1" \
        saamode="optimized" tentacle="yes"
    # 失敗したら`rm -r $My_Nustar_Dir/out`
done
cd $My_Nustar_D
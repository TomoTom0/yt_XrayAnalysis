# _SuzakuXis_a_beforeDs9
# _SuzakuXis_1_ds9
## ds9
echo ${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do

    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
    if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi
    cd $My_Suzaku_Dir
    evt_lists=($(ls ae*xi1*3x3*.evt*))
    evt_file=${evt_lists[0]}

    if [[ ! -f ${My_Suzaku_D}/saved.reg ]]; then
        # saved.regが存在しないなら、新たに作成する
        declare -A tmp_dict=(["RA_OBJ"]="0" ["DEC_OBJ"]="0")
        for key in ${!tmp_dict[@]}; do
            # fits headerから座標を読み取る
            tmp_dict[$key]=$(fkeyprint infile="${evt_file}+1" keynam="${key}" |
                grep "${key}\s*=" |
                sed -r -n "s/^.*${key}\s*=\s*(.*)\s*\/.*$/\1/p")
        done
        ra=$(echo ${tmp_dict[RA_OBJ]} |
            sed -r "s/E([\+\-]?[0-9]+)/*10^\1/" |
            sed -r "s/10\^\+?(-?)0*([0-9]+)/10^(\1\2)/" | bc)
        dec=$(echo ${tmp_dict[DEC_OBJ]} |
            sed -r "s/E([\+\-]?[0-9]+)/*10^\1/" |
            sed -r "s/10\^\+?(-?)0*([0-9]+)/10^(\1\2)/" | bc)
        # background circleはとりあえず0.05 degずつずらした点
        ra_bkg=$(echo "$ra + 0.05 " | bc)
        dec_bkg=$(echo "$dec + 0.05 " | bc)
        # 半径はとりあえず0.026 deg = 100 arcsec
        ds9 $evt_file \
            -regions system fk5 \
            -regions command "fk5; circle $ra $dec 0.026 # source" \
            -regions command "fk5; circle $ra_bkg $dec_bkg 0.026 # background" \
            -regions save $My_Suzaku_D/saved.reg -exit
    fi
    cp ${My_Suzaku_D}/saved.reg xis.reg -f
    echo "----  save as xis.reg with overwriting  ----"
    ds9 $evt_file \
        -scale log -cmap bb -mode region \
        -regions load xis.reg
    ### adjust xis.reg

    cp xis.reg ${My_Suzaku_D}/saved.reg -f

    reg_file=xis.reg
    cat ${reg_file} | grep -v -E "^circle.*# background" >src.reg
    cat ${reg_file} | grep -v -E "^circle.*\)$" >bkg.reg

done

cd $My_Suzaku_D
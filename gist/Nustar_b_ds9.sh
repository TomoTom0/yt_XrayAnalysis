# _Nustar_b_ds9
# _Nustar_2_ds9
## ds9で領域指定
echo ${My_Nustar_D:=$(pwd)} # 未定義時に代入
cd $My_Nustar_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir/out ]]; then continue; fi
    cd $My_Nustar_Dir/out

    if [[ ! -f ${My_Nustar_D}/saved.reg ]]; then
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
            -regions save $My_Nustar_D/saved.reg -exit
    fi
    cp ${My_Nustar_D}/saved.reg fpmA.reg -f
    echo "----  save as fpmA.reg with overwriting  ----"
    ds9 nu${My_Nustar_ID}A01_cl.evt \
        -scale log -cmap bb -mode region \
        -regions load fpmA.reg
    ### adjust fpmA.reg

    cp fpmA.reg fpmB.reg -f
    echo "----  save as fpmB.reg with overwriting  ----"
    ds9 nu${My_Nustar_ID}B01_cl.evt \
        -scale log -cmap bb -mode region \
        -region load fpmB.reg
    ### adjust fpmB.reg

    cp fpmB.reg ${My_Nustar_D}/saved.reg -f

    for reg_file in $(find . -name "fpm[AB].reg" -printf "%f\n"); do
        cam=$(echo ${reg_file} | sed -r -n "s/^.*fpm(A|B)\.reg$/\1/p")
        cat ${reg_file} | grep -v -E "^circle.*# background" >src${cam}.reg
        cat ${reg_file} | grep -v -E "^circle.*\)$" >bkg${cam}.reg
    done
done

cd $My_Nustar_D
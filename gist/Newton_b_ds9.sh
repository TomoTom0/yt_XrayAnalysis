# _Newton_b_ds9
# _Newton_3_ds9
## ds9で領域指定
echo ${My_Newton_D:=$(pwd)}
cd $My_Newton_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do

    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi

    cd $My_Newton_Dir/fit
    _evt_tmps=($(find $My_Newton_Dir/fit/ -name "*_filt_time.fits"))
    evt_file=${_evt_tmps[0]}
    if [[ ! -r ${My_Newton_D}/saved.reg ]]; then
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
            -regions save $My_Newton_D/saved.reg -exit
    fi

    for cam in ${all_cams[@]}; do
        cp ${My_Newton_D}/saved.reg ${cam}.reg -f
        echo "----  save as ${cam}.reg with overwriting  ----"
        ds9 $My_Newton_Dir/fit/${cam}_filt_time.fits \
            -scale log -cmap bb -mode region \
            -bin factor 16 -regions load ${cam}.reg
        ### adjust mos1.reg, mos2.reg, pn.reg
        cp ${cam}.reg ${My_Newton_D}/saved.reg -f
    done
done
cd $My_Newton_D

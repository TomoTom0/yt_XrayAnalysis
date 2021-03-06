# _SwiftXrt_b_ds9
# _SwiftXrt_2_ds9
## ds9で領域指定
echo ${My_Swift_D:=$(pwd)} # 未定義時に代入
cd $My_Swift_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir/xrt/out ]]; then continue; fi
    cd $My_Swift_Dir/xrt/output
    evt_tmps=($(ls -r sw${My_Swift_ID}xpcw*po_cl.evt))
    evt_file=${evt_tmps[0]}

    if [[ ! -f ${My_Swift_D}/saved.reg ]]; then
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
            -regions save $My_Swift_D/saved.reg -exit
    fi
    reg_file=xrt.reg
    cp ${My_Swift_D}/saved.reg $reg_file -f
    echo "----  save as $reg_file with overwriting  ----"
    ds9 $evt_file \
        -scale log -cmap bb -mode region \
        -regions load $reg_file
    ### adjust xrt.reg

    cp $reg_file ${My_Swift_D}/saved.reg -f

    cat ${reg_file} | grep -v -E "^circle.*# background" >src.reg
    cat ${reg_file} | grep -v -E "^circle.*\)$" >bkg.reg
done

cd $My_Swift_D
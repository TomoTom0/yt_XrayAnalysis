# _Nustar_b_ds9
# _Nustar_2_ds9
## ds9で領域指定
FLAG_simple=false # arg
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Nustar_D=${My_Nustar_D:=$(pwd)} 
else 
    declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} 
fi # 未定義時に代入
cd $My_Nustar_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir/out ]]; then continue; fi
    cd $My_Nustar_Dir/out

    evt_file=nu${My_Nustar_ID}A01_cl.evt

    if [[ ! -f ${My_Nustar_D}/saved.reg && ${FLAG_simple:=false} == false ]]; then
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
        cat <<EOF > ${My_Nustar_D}/saved.reg
# Region file format: DS9 version 4.1
global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1
fk5
circle($ra,$dec,0.026)
circle($ra_bkg,$dec_bkg,0.026) # background
EOF
    fi
    for cam in A B; do
        if [[ ${FLAG_simple:=false} == false ]]; then
            cp ${My_Nustar_D}/saved.reg fpm${cam}.reg -f
            echo ""
            echo "----  save as fpm${cam}.reg with overwriting  ----"
            echo ""
            ds9 nu${My_Nustar_ID}${cam}01_cl.evt \
                -scale log -cmap bb -mode region \
                -regions load fpm${cam}.reg
            ### adjust fpmA.reg / fpmB.reg
            cp fpm${cam}.reg ${My_Nustar_D}/saved.reg -f

            cat fpm${cam}.reg | grep -v -E "^circle.*# background" >src${cam}.reg
            cat fpm${cam}.reg | grep -v -E "^circle.*\)$" >bkg${cam}.reg
        else
            echo ""
            echo "----  save as fpm${cam}.reg  ----"
            echo ""
            ds9 nu${My_Nustar_ID}${cam}01_cl.evt \
                -scale log -cmap bb -mode region
            ### make fpmA.reg / fpmB.reg
        fi
    done

done

cd $My_Nustar_D
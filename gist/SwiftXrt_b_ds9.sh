# _SwiftXrt_b_ds9
# _SwiftXrt_2_ds9
## ds9で領域指定
FLAG_simple=false # arg
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Swift_D=${My_Swift_D:=$(pwd)} 
else 
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
fi # 未定義時に代入
cd $My_Swift_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir/xrt/output ]]; then continue; fi
    cd $My_Swift_Dir/xrt/output
    _evt_tmps=($(find . -name sw${My_Swift_ID}xpcw*po_cl.evt))
    evt_file=${_evt_tmps[-1]}

    if [[ ! -f ${My_Swift_D}/saved.reg && ${FLAG_simple:=false} == false ]]; then
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
        cat <<EOF > ${My_Swift_D}/saved.reg
# Region file format: DS9 version 4.1
global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1
fk5
circle($ra,$dec,0.026)
circle($ra_bkg,$dec_bkg,0.026) # background
EOF
    fi
    reg_file=xrt.reg
    if [[ ! -f "${evt_file}"  ]]; then
        echo ""
        echo "----   event_file not found"
        echo ""
        continue
    elif [[ ${FLAG_simple:=false} == false  ]]; then
        cp ${My_Swift_D}/saved.reg $reg_file -f
        echo ""
        echo "----  opening $evt_file"
        echo "----  save as $reg_file with overwriting"
        echo ""
        ds9 $evt_file \
            -scale log -cmap bb -mode region \
            -regions load $reg_file
        ### adjust xrt.reg

        tmp_reg="tmp.reg"
        ds9 $evt_file -regions load $reg_file -regions system fk5 \
            -regions centroid -regions save $tmp_reg -exit &&
        cp $tmp_reg ${My_Swift_D}/saved.reg -f

        cat $tmp_reg | grep -v -E "^(circle|annulus).*# background" > src.reg
        cat $tmp_reg | grep -v -E "^(circle|annulus).*\)$" > bkg.reg
    else
        echo ""
        echo "----  opening $evt_file"
        echo "----  save as $reg_file"
        echo ""
        ds9 $evt_file \
            -scale log -cmap bb -mode region
    fi
done

cd $My_Swift_D
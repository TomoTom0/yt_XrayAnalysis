# _SwiftUvot_2_products
## products
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then
    My_Swift_D=${My_Swift_D:=$(pwd)}
else
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
fi # 未定義時に代入
cd $My_Swift_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir/uvot/image ]]; then continue; fi

    cd $My_Swift_Dir/uvot/image
    mkdir $My_Swift_Dir/uvot/image/fit -p
    img_files=($(find . -name "sw${My_Swift_ID}*_sk.img*" -printf "%f\n"))
    for img_file in ${img_files[@]}; do
        band=$(echo $img_file | sed -e "s/sw${My_Swift_ID}\(.*\)_sk.img.gz/\1/g")

        if [[ "x$band" == "x" ]]; then continue; fi

        # rspのシンボリックリンク作成
        ## uvotにarfは不要
        _rsp_tmps=($(find "${CALDB}/data/swift/uvota/cpf/rsp/" -name "sw${band}_*.rsp" | sort -r))
        rsp_file=${_rsp_tmps[-1]}
        rm fit/tmp_uvot__${band}_rsp.fits -f &&
            ln -s "$rsp_file" fit/tmp_uvot__${band}_rsp.fits

        #rm tmp_${band}.fits -f
        ## uvotimsumは不要?? 公式でもmanualと手順の場所でばらついてる
        #uvotimsum infile=${img_file} outfile=tmp_${band}.fits chatter=1
        if [[ ! -f "src_${band}.reg" ]]; then
            echo $My_Swift_ID $band
        continue; fi
        rm fit/tmp_uvot__${band}_src.fits \
            fit/tmp_uvot__${band}_bkg.fits -f
        uvot2pha infile=${img_file}+1 srcreg=src_${band}.reg \
            bkgreg=bkg_${band}.reg \
            srcpha=fit/tmp_uvot__${band}_src.fits \
            bkgpha=fit/tmp_uvot__${band}_bkg.fits \
            respfile=fit/tmp_uvot__${band}_rsp.fits \
            clobber=y chatter=1

    done

done
cd $My_Swift_D
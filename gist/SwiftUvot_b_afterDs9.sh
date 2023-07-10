# _SwiftUvot_b_afterDs9
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
        rsp_file=${_rsp_tmps[0]}
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
# _SwiftUvot_3_addascaspec
## obtain rmf
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then
    My_Swift_D=${My_Swift_D:=$(pwd)}
else
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
fi # 未定義時に代入
cd $My_Swift_D

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir/uvot/image/fit ]]; then continue; fi

    cd $My_Swift_Dir/uvot/image/fit

    find . -name "tmp_uvot__*.fits" |
        rename "s/tmp_uvot__/tmp_uvot_${My_Swift_ID}_/" -f

    uvot_band_all=($(find . -name "tmp_uvot_${My_Swift_ID}_*_src.fits" -printf "%f\n" |
        sed -r "s/^tmp_uvot_${My_Swift_ID}_([a-z0-9]+)_.*$/\1/"))
    uvot_band_sum=$(echo ${uvot_band_all[@]} | sed "s/ /_/g")
    new_uvot_names=($(echo -n "src rsp bkg" | xargs -n 1 -d" " \
        -i echo uvot_${My_Swift_ID}_${uvot_band_sum}_{}.fits))
    rm uvot_*.fits -f
    if [[ ! 1 && ${#uvot_band_all[@]} -ge 2 ]]; then

        cat <<EOF >tmp_fi.add
$(find . -name "tmp_uvot_${My_Swift_ID}_*_src.fits" -printf "%P ")
$(find . -name "tmp_uvot_${My_Swift_ID}_*_bkg.fits" -printf "%P ")
$(find . -name "tmp_uvot_${My_Swift_ID}_*_rsp.fits" -printf "%P ")
EOF

        rm ${new_uvot_names[@]} -f
        addascaspec tmp_fi.add ${new_uvot_names[@]}
    fi

    if [[ ${#uvot_band_all[@]} -ge 1 ]]; then
        for band in ${uvot_band_all[@]}; do
            #band=${uvot_band_sum}
            echo -n "bkg rsp" | xargs -n 1 -i -d" " cp tmp_uvot_${My_Swift_ID}_${band}_{}.fits uvot_${My_Swift_ID}_${band}_{}.fits -f
            cat <<EOF | bash
grppha infile=tmp_uvot_${My_Swift_ID}_${band}_src.fits outfile=uvot_${My_Swift_ID}_${band}_src.fits clobber=true
chkey BACKFILE uvot_${My_Swift_ID}_${band}_bkg.fits
chkey RESPFILE uvot_${My_Swift_ID}_${band}_rsp.fits+1
exit
EOF
        done
    fi
done

cd $My_Swift_D
# _SwiftUvot_4_fitDirectory
## fitディレクトリにまとめ
FLAG_hardCopy=false # arg
FLAG_symbLink=false # arg
tmp_prefix="uvot_" # arg
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then
    My_Swift_D=${My_Swift_D:=$(pwd)}
else
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
fi # 未定義時に代入
cd $My_Swift_D
mkdir -p $My_Swift_D/fit $My_Swift_D/../fit
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
for My_Swift_ID in ${obs_dirs[@]}; do
    if [[ ${FLAG_symbLink:=false} == "true" ]]; then
        find $My_Swift_D/$My_Swift_ID/uvot/image/fit/ -name "${tmp_prefix}*.*" \
            -type f -printf "%f\n" |
            xargs -n 1 -i rm -f $My_Swift_D/fit/{}
        ln -s $My_Swift_D/$My_Swift_ID/uvot/image/fit/${tmp_prefix}* ${My_Swift_D}/fit/
    else
        if [[ ! -d "$My_Swift_D/$My_Swift_ID/uvot/image/fit/" ]]; then continue; fi
        find $My_Swift_D/$My_Swift_ID/uvot/image/fit/ -name "${tmp_prefix}*" | xargs -i cp {} ${My_Swift_D}/fit/
        #cp -f $My_Swift_D/$My_Swift_ID/uvot/image/fit/${tmp_prefix}* ${My_Swift_D}/fit/
    fi
done
if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
    cp -f $My_Swift_D/fit/${tmp_prefix}*.* $My_Swift_D/../fit/
else
    # remove the files with the same name as new files
    find $My_Swift_D/fit/ -name "${tmp_prefix}*.*" \
        -type f -printf "%f\n" |
        xargs -n 1 -i rm -f $My_Swift_D/../fit/{}
    # generate symbolic links
    ln -s $My_Swift_D/fit/${tmp_prefix}*.* $My_Swift_D/../fit/
fi
# remove broken symbolic links
find -L $My_Swift_D/../fit/ -type l -delete
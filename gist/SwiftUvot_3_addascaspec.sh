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
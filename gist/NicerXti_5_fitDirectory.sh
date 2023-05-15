# _NicerXti_5_fitDirectory
## fitディレクトリにまとめ
FLAG_hardCopy=false # arg
FLAG_symbLink=false # arg
tmp_prefix="xrt_" # arg
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then
    My_Nicer_D=${My_Nicer_D:=$(pwd)}
else
    declare -g My_Nicer_D=${My_Nicer_D:=$(pwd)}
fi # 未定義時に代入
cd $My_Nicer_D
mkdir -p $My_Nicer_D/fit $My_Nicer_D/../fit
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
for My_Nicer_ID in ${obs_dirs[@]}; do
    fit_path=$My_Nicer_D/$My_Nicer_ID/xti/event_cl/fit
    if [[ ${FLAG_symbLink:=false} == "true" ]]; then
        #find $fit_path -name "${tmp_prefix}*.*" \
        #    -type f -printf "%f\n" |
        #    xargs -n 1 -i rm -f $My_Nicer_D/fit/{}
        ln -nfs ${fit_path}/${tmp_prefix}* ${My_Nicer_D}/fit/
    else
        if [[ ! -d "$fit_path" ]]; then continue; fi
        find $fit_path -name "${tmp_prefix}*" | xargs -i cp {} ${My_Nicer_D}/fit/
        #cp -f $fit_path/${tmp_prefix}* ${My_Nicer_D}/fit/
    fi
done
if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
    cp -f $My_Nicer_D/fit/${tmp_prefix}*.* $My_Nicer_D/../fit/
else
    # remove the files with the same name as new files
    #find $My_Nicer_D/fit/ -name "${tmp_prefix}*.*" \
    #    -type f -printf "%f\n" |
    #    xargs -n 1 -i rm -f $My_Nicer_D/../fit/{}
    # generate symbolic links
    ln -nfs $My_Nicer_D/fit/${tmp_prefix}*.* $My_Nicer_D/../fit/
fi
# remove broken symbolic links
find -L $My_Nicer_D/../fit/ -type l -delete
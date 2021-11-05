# _SuzakuHxd_7_fitDirectory
##    to fit directory
FLAG_hardCopy=false # arg
FLAG_symbLink=false # arg
tmp_prefix="hxd_" # arg
declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D

mkdir -p $My_Suzaku_D/fit $My_Suzaku_D/../fit
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do
    if [[ ${FLAG_symbLink:=false} == "true" ]]; then
        find $My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl/fit/ -name "${tmp_prefix}*.*" \
            -type f -printf "%f\n" |
            xargs -n 1 -i rm -f $My_Suzaku_D/fit/{}
        ln -s $My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl/fit/${tmp_prefix}* ${My_Suzaku_D}/fit/
    else
        cp -f $My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl/fit/${tmp_prefix}* ${My_Suzaku_D}/fit/
    fi
done
if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
    cp -f $My_Suzaku_D/fit/${tmp_prefix}*.* $My_Suzaku_D/../fit/
else
        # remove the files with the same name as new files
    find $My_Suzaku_D/fit/ -name "${tmp_prefix}*.*" \
        -type f -printf "%f\n" |
        xargs -n 1 -i rm -f $My_Suzaku_D/../fit/{}
    # generate symbolic links
    ln -s $My_Suzaku_D/fit/${tmp_prefix}*.* $My_Suzaku_D/../fit/
fi
# remove broken symbolic links
find -L $My_Suzaku_D/../fit/ -type l -delete

cd $My_Suzaku_D

# _SuzakuHxd_7_fitDirectory
# to fit directory
echo ${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D

mkdir -p fit $My_Suzaku_D/../fit
tmp_prefix="hxd_"
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do
    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
    mkdir $My_Suzaku_D/fit -p
    cp $My_Suzaku_Dir/fit/${tmp_prefix}*.* $My_Suzaku_D/fit/ -f
done
find $My_Suzaku_D/fit/ -name "${tmp_prefix}*.*" \
    -type f -printf "%f\n" |
    xargs -n 1 -i rm -f $My_Suzaku_D/../fit/{}
find -L $My_Suzaku_D/../fit/ -type l -delete
ln -s $My_Suzaku_D/fit/${tmp_prefix}*.* $My_Suzaku_D/../fit/
cd $My_Suzaku_D
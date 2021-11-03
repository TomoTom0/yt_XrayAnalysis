# _SuzakuXis_7_fitDirectory
## fitディレクトリにまとめ
echo ${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D
tmp_prefix=xis_
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
mkdir -p $My_Suzaku_D/fit $My_Suzaku_D/../fit
for My_Suzaku_ID in ${obs_dirs[@]}; do
    cp $My_Suzaku_D/$My_Suzaku_ID/xis/event_cl/fit/${tmp_prefix}*.* $My_Suzaku_D/fit/ -f
done
### remove the files with the same name as new files
find $My_Suzaku_D/fit/ -name "${tmp_prefix}*.*" \
    -type f -printf "%f\n" |
    xargs -n 1 -i rm -f $My_Suzaku_D/../fit/{}
### remove broken symbolic links
find -L $My_Suzaku_D/../fit/ -type l -delete
### generate symbolic links
ln -s $My_Suzaku_D/fit/${tmp_prefix}*.* $My_Suzaku_D/../fit/

cd $My_Suzaku_D
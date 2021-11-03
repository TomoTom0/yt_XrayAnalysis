# _Nustar_7_fitDirectory
## fitディレクトリにまとめ
echo ${My_Nustar_D:=$(pwd)} # 未定義時に代入
cd $My_Nustar_D
tmp_prefix="AB_"
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
mkdir -p $My_Nustar_D/fit $My_Nustar_D/../fit/
for My_Nustar_ID in ${obs_dirs[@]}; do
    cp $My_Nustar_D/$My_Nustar_ID/fit/${tmp_prefix}* $My_Nustar_D/fit/ -f
done
### remove the files with the same name as new files
find $My_Nustar_D/fit/ -name "${tmp_prefix}*.*" \
    -type f -printf "%f\n" |
    xargs -n 1 -i rm -f $My_Nustar_D/../fit/{}
### remove broken symbolic links
find -L $My_Nustar_D/../fit/ -type l -delete
### generate symbolic links
ln -s $My_Nustar_D/fit/${tmp_prefix}*.* $My_Nustar_D/../fit/
cd $My_Nustar_D
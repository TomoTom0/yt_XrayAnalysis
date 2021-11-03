# _SwiftXrt_7_fitDirectory
## fitディレクトリにまとめ
echo ${My_Swift_D:=$(pwd)} # 未定義時に代入
cd $My_Swift_D
tmp_prefix="xrt_"
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
mkdir -p $My_Swift_D/fit $My_Swift_D/../fit/
for My_Swift_ID in ${obs_dirs[@]}; do
    cp $My_Swift_D/$My_Swift_ID/xrt/output/fit/${tmp_prefix}* $My_Swift_D/fit/ -f
done
### remove the files with the same name as new files
find $My_Swift_D/fit/ -name "${tmp_prefix}*.*" \
    -type f -printf "%f\n" |
    xargs -n 1 -i rm -f $My_Swift_D/../fit/{}
### remove broken symbolic links
find -L $My_Swift_D/../fit/ -type l -delete
### generate symbolic links
ln -s $My_Swift_D/fit/${tmp_prefix}*.* $My_Swift_D/../fit/
# _Newton_10_fitDirectory
## fitディレクトリにまとめ
echo ${My_Newton_D:=$(pwd)}
cd $My_Newton_D
tmp_prefix=newton_
mkdir -p $My_Newton_D/fit $My_Newton_D/../fit/

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do
    cp $My_Newton_D/$My_Newton_ID/ODF/fit/${tmp_prefix}* ${My_Newton_D}/fit/ -f
done
### remove the files with the same name as new files
find $My_Newton_D/fit/ -name "${tmp_prefix}*.*" \
    -type f -printf "%f\n" |
    xargs -n 1 -i rm -f $My_Newton_D/../fit/{}
### remove broken symbolic links
find -L $My_Newton_D/../fit/ -type l -delete
### generate symbolic links
ln -s $My_Newton_D/fit/${tmp_prefix}*.* $My_Newton_D/../fit/
cd $My_Newton_D
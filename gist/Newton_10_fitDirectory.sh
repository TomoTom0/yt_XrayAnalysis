# _Newton_10_fitDirectory
## fitディレクトリにまとめ
FLAG_hardCopy=false # arg
FLAG_symbLink=false # arg
tmp_prefix="newton_" # arg
declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
cd $My_Newton_D
mkdir -p $My_Newton_D/fit $My_Newton_D/../fit/

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do
    if [[ ${FLAG_symbLink:=false} == "true" ]]; then
        cp -f $My_Newton_D/$My_Newton_ID/ODF/fit/${tmp_prefix}* ${My_Newton_D}/fit/
    else
        find $My_Newton_D/$My_Newton_ID/ODF/fit/ -name "${tmp_prefix}*.*" \
            -type f -printf "%f\n" |
            xargs -n 1 -i rm -f $My_Newton_D/fit/{}
        ln -s $My_Newton_D/$My_Newton_ID/ODF/fit/${tmp_prefix}* ${My_Newton_D}/fit/
    fi
done
if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
    # remove the files with the same name as new files
    find $My_Newton_D/fit/ -name "${tmp_prefix}*.*" \
        -type f -printf "%f\n" |
        xargs -n 1 -i rm -f $My_Newton_D/../fit/{}
    # generate symbolic links
    ln -s $My_Newton_D/fit/${tmp_prefix}*.* $My_Newton_D/../fit/
else
    cp -f $My_Newton_D/fit/${tmp_prefix}*.* $My_Newton_D/../fit/
fi
# remove broken symbolic links
find -L $My_Newton_D/../fit/ -type l -delete

cd $My_Newton_D
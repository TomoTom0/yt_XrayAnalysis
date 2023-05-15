# _SwiftXrtBuild_4_fitDirectory
## fitディレクトリにまとめ
FLAG_hardCopy=false # arg
FLAG_symbLink=false # arg
tmp_prefix="xrtBuild" # arg
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Swift_D=${My_Swift_D:=$(pwd)} 
else 
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
fi # 未定義時に代入
cd $My_Swift_D
mkdir -p $My_Swift_D/fit $My_Swift_D/../fit
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Swift_ID in ${obs_dirs[@]}; do
    prod_IDs=($(find . -maxdepth 1 -type d -printf "%P\n" |
        grep ^xrt_build_[0-9] |
        sed -r -n "s/^xrt_build_([0-9]+)$/\1/p"))
    for prod_ID in ${prod_IDs[@]}; do
        if [[ ${FLAG_symbLink:=false} == "true" ]]; then
            find "$My_Swift_D/xrt//xrt_build_${prod_ID}/spec/fit/" -name "${tmp_prefix}*.*" \
                -type f -printf "%f\n" |
                xargs -i rm -f $My_Swift_D/fit/{} #xargs -n 1 -i rm -f $My_Swift_D/fit/{}
            find "$My_Swift_D/xrt//xrt_build_${prod_ID}/spec/fit/" -name "${tmp_prefix}*.*" -type f -printf "%p\n" |
                xargs -i ln -s {} $My_Swift_D/fit/
        else
            find "$My_Swift_D/xrt//xrt_build_${prod_ID}/spec/fit/" -name "${tmp_prefix}*.*" -type f -printf "%p\n" |
                xargs -i cp {} $My_Swift_D/fit/
        fi
    done
done
if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
    cp -f $My_Swift_D/fit/${tmp_prefix}*.* $My_Swift_D/../fit/
else
    # remove the files with the same name as new files
    find $My_Swift_D/fit/ -name "${tmp_prefix}*.*" -type f -printf "%f\n" |
        xargs -n 1 -i rm -f $My_Swift_D/../fit/{}
    # generate symbolic links
    ln -s $My_Swift_D/fit/${tmp_prefix}*.* $My_Swift_D/../fit/
fi
# remove broken symbolic links
find -L $My_Swift_D/../fit/ -type l -delete
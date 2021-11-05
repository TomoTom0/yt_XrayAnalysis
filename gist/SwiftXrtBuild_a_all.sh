# _SwiftXrtBuild_a_all
# _SwiftXrtBuild_1_downloadData
## download Data
declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
if [[ "x${url}" != "x" ]]; then
    prod_ID=$(echo $url | sed -r -n "s/^.*\/USERPROD_([0-9]+)\/.*$/\1/p")
    ext=${url##*.}
    My_Swift_Dir=$My_Swift_D/xrt/xrt_build_${prod_ID}
    mkdir $My_Swift_Dir -p
    if [[ ! -r $My_Swift_Dir ]]; then continue; fi
    cd $My_Swift_Dir

    tmp_file=tmp.${ext}
    wget $url -O $tmp_file
    tar xvf $tmp_file

    if [[ "x${ext}" == "xtar" ]]; then
        ## par ObsID
        cd $My_Swift_Dir/USERPROD_${prod_ID}/spec
        find . -name "*.gz" | xargs -n 1 tar xvf
    elif [[ "x${ext}" == "xgz" ]]; then
        ## Other Cases
        find . -name "*.gz" | xargs -n 1 tar xvf
    fi
fi
cd $My_Swift_D
# _SwiftXrtBuild_1_downloadData
## download Data
declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
if [[ "x${url}" != "x" ]]; then
    prod_ID=$(echo $url | sed -r -n "s/^.*\/USERPROD_([0-9]+)\/.*$/\1/p")
    ext=${url##*.}
    My_Swift_Dir=$My_Swift_D/xrt/xrt_build_${prod_ID}
    mkdir $My_Swift_Dir -p
    if [[ ! -r $My_Swift_Dir ]]; then continue; fi
    cd $My_Swift_Dir

    tmp_file=tmp.${ext}
    wget $url -O $tmp_file
    tar xvf $tmp_file

    if [[ "x${ext}" == "xtar" ]]; then
        ## par ObsID
        cd $My_Swift_Dir/USERPROD_${prod_ID}/spec
        find . -name "*.gz" | xargs -n 1 tar xvf
    elif [[ "x${ext}" == "xgz" ]]; then
        ## Other Cases
        find . -name "*.gz" | xargs -n 1 tar xvf
    fi
fi
cd $My_Swift_D
# _SwiftXrtBuild_3_grppha
## grppha
gnum=10 # arg
declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
cd $My_Swift_D/xrt

prod_IDs=($(find . -maxdepth 1 -type d -printf "%P\n" |
    grep ^xrt_build_[0-9] |
    sed -r -n "s/^xrt_build_([0-9]+)$/\1/p"))
for prod_ID in ${prod_IDs[@]}; do
    spec_path=$My_Swift_D/xrt/xrt_build_${prod_ID}/spec
    if [[ ! -r $spec_path ]]; then continue; fi
    cd $spec_path/fit

    nongrp_names=($(find . -name "xrtBuild*_nongrp.fits" -printf "%f\n"))
    for nongrp_name in ${nongrp_names[@]}; do
        tmp_head=${nongrp_name/_nongrp.fits/}
        grp_name=${tmp_head}_grp${gnum}.fits
        grpauto_name=${tmp_head}_grpauto.fits

        declare -A tr_keys=(
            ["BACKFILE"]=${tmp_head}_bkg.fits
            ["RESPFILE"]=${tmp_head}_rmf.fits
            ["ANCRFILE"]=${tmp_head}_arf.fits)

        for key in ${!tr_keys[@]}; do
            fparkey value="${tr_keys[$key]}" \
                fitsfile=${nongrp_name}+1 \
                keyword="${key}" add=yes
        done

        for key in ${!tr_keys[@]}; do
            fparkey value="${tr_keys[$key]}" \
                fitsfile=${grpauto_name}+1 \
                keyword="${key}" add=yes
        done

        cat <<EOF | bash
grppha infile=$nongrp_name outfile=$grp_name
group min $gnum
exit !$grp_name
EOF

    done
done
cd $My_Swift_D
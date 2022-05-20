# _SwiftXrt_3_products
## xrtproducts
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
fi # 未定義時に代入
cd $My_Swift_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir/xrt/output ]]; then continue; fi

    cd $My_Swift_Dir/xrt/output
    _evt_tmps=($(find . -name "sw${My_Swift_ID}xpcw*po_cl.evt" -printf "%f\n"))
    evt_file=${_evt_tmps[-1]}

    _exp_tmps=($(find . -name "sw${My_Swift_ID}xpcw*po_ex.img" -printf "%f\n"))
    exp_file=${_exp_tmps[0]}

    if [[ ! -f "$evt_file" || ! -f "$evt_file" ]]; then continue; fi

    # unable to open xrt__nongrp.fitsで動かない……とりあえずxselectで代用
    #rm $My_Swift_Dir/xrt/output/fit/* -rf
    #xrtproducts infile=$evt_file stemout=DEFAULT regionfile=src.reg \
    #    bkgregionfile=bkg.reg bkgextract=yes outdir="$My_Swift_Dir/xrt/output/fit" binsize=-99 \
    #    expofile=$exp_file clobber=yes correctlc=no \
    #    phafile=xrt__nongrp.fits bkgphafile=xrt__bkg.fits arffile=xrt__arf.fits

    cat <<EOF | bash
xselect
xsel
read events $evt_file
./
y
extract all
filter region src.reg
extract spectrum
save spectrum xrt__nongrp.fits
clear region
filter region bkg.reg
extract spectrum
save spectrum xrt__bkg.fits
exit
n

EOF

    cat << EOF | bash
xrtmkarf phafile=xrt__nongrp.fits srcx=-1 srcy=-1 outfile=xrt__arf.fits extended=no expofile=${exp_file}
yes
EOF
    mkdir fit -p
    mv xrt__nongrp.fits xrt__bkg.fits xrt__arf.fits fit/

done
cd $My_Swift_D
# _SwiftXrt_3_products
## xrtproducts
echo ${My_Swift_D:=$(pwd)} # 未定義時に代入
cd $My_Swift_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir/xrt/output ]]; then continue; fi

    cd $My_Swift_Dir/xrt/output
    _evt_tmps=($(ls -r sw${My_Swift_ID}xpcw*po_cl.evt))
    evt_file=${_evt_tmps[-1]}

    _exp_tmps=($(ls -r sw${My_Swift_ID}xpcw*po_ex.img))
    exp_file=${_exp_tmps[0]}
    xrtproducts infile=$evt_file stemout=DEFAULT regionfile=src.reg \
        bkgregionfile=bkg.reg bkgextract=yes outdir=$My_Swift_Dir/xrt/output/fit binsize=-99 \
        expofile=$exp_file clobber=yes correctlc=no \
        phafile=xrt__nongrp.fits bkgphafile=xrt__bkg.fits arffile=xrt__arf.fits

done
cd $My_Swift_D
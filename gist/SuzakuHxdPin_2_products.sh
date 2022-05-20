# _SuzakuHxdPin_2_products
## hxdpinxbpi
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
fi
cd $My_Suzaku_D
nxb_evt=ae_hxdPin_nxb.evt

function _Obtain_SuzakuHxdPin_RspIndex() {
    input_mjd=${1%%\.[0-9]*}
    date_standards=(53600 53881 54012 54311 54710 55106 55213 55229 55290 55532 55708)
    count=0
    for data_stan in ${date_standards[@]}; do
        if [[ ! $input_mjd =~ [0-9]+ ||
            $data_stan -ge $input_mjd ]]; then
            break
        fi
        count=$(($count + 1))
    done
    echo $count
}

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do
    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
    if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

    cd $My_Suzaku_Dir
    _pin_tmps=($(ls ae${My_Suzaku_ID}hxd_0_pinno_cl*.evt*))
    pin_file=${_pin_tmps[0]}

    _pse_tmp=($(ls ae${My_Suzaku_ID}hxd_0_pse_cl*.evt*))
    pse_file=${_pse_tmp[0]}

    ### merge gti
    gti_file=tmp_pin.gti
    rm $gti_file -f &&
        mgtime ingtis="${pin_file}+2,tmp_nxb.evt+2" \
            outgti=$gti_file merge="AND"

    hxdpinxbpi input_fname=${pin_file} pse_event_fname=${pse_file} \
        bkg_event_fname=${nxb_evt} outstem=tmp_ \
        gti_fname=$gti_file cxb_fname=CALC \
        groupspec=yes clobber=yes

    obs_MJD_tmp_float=($(fkeyprint infile="${pin_file}" keynam="MJD-OBS" |
        grep "MJD-OBS\s*=" |
        sed -r -n "s/^.*MJD-OBS\s*=\s*(.*)\s*\/.*$/\1/p"))
    obs_MJD=$(printf "%.0f" ${obs_MJD_tmp_float[0]})

    rsp_index=$(_Obtain_SuzakuHxdPin_RspIndex ${obs_MJD})
    rsp_files_CALDB=($(find $CALDB/data/suzaku/hxd/cpf/ -name "ae_hxd_pinhxnome${rsp_index}*.rsp"))
    rspFlat_files_CALDB=($(find $CALDB/data/suzaku/hxd/cpf/ -name "ae_hxd_pinflate${rsp_index}*.rsp"))
    #_rsp_tmps=($(find . -name "ae_hxd_pinxnome*.rsp" -printf "%f\n")  ${rsp_files_CALDB[@]})
    rsp_file=${rsp_files_CALDB[-1]}
    #_rspFlat_tmps=($(find . -name "ae_hxd_pinflate*.rsp" -printf "%f\n") ${rsp_files_CALDB[@]})
    rspFlat_file=${rsp_files_CALDB[-1]}

    rm -f hxdPin__rmf.fits hxdPin__rmfFlat.fits
    ln -s ${rsp_file} hxdPin__rmf.fits
    ln -s ${rspFlat_file} hxdPin__rmfFlat.fits

    declare -A rename_dic=(
        ["tmp_hxd_pin_sr.pi"]=hxdPin__nongrp.fits
        ["tmp_hxd_pin_sr_grp.pi"]=hxdPin__grpauto.fits
        ["tmp_hxd_pin_bg.pi"]=hxdPin__bkg.fits
        ["tmp_hxd_pin_nxb.pi"]=hxdPin__nxb.fits
        ["tmp_hxd_pin_cxb.pi"]=hxdPin__cxb.fits
        )
    for oldName in ${!rename_dic[@]}; do
        mv -f $oldName ${rename_dic[$oldName]}
    done
    rm ${My_Suzaku_Dir}/fitPin -rf
    mkdir ${My_Suzaku_Dir}/fitPin -p
    mv -f hxdPin__* ${My_Suzaku_Dir}/fitPin

done
cd $My_Suzaku_D
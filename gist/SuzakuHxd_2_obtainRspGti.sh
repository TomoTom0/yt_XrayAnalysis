# _SuzakuHxd_2_obtainRspGti
## set rsp, gti
echo ${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D

function _Obtain_SuzakuHxd_RspIndex() {
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

for My_Suzaku_ID in ${obs_dirs[@]}; do
    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
    if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

    cd $My_Suzaku_Dir
    _pin_tmps=($(ls ae${My_Suzaku_ID}hxd_0_pinno_cl*.evt*))
    pin_file=${_pin_tmps[0]}

    obs_MJD_tmp_float=($(fkeyprint infile="${pin_file}" keynam="MJD-OBS" |
        grep "MJD-OBS\s*=" |
        sed -r -n "s/^.*MJD-OBS\s*=\s*(.*)\s*\/.*$/\1/p"))
    obs_MJD=$(printf "%.0f" ${obs_MJD_tmp_float[0]})

    rsp_index=$(_Obtain_SuzakuHxd_RspIndex ${obs_MJD})
    _rsp_tmps=($(ls $CALDB/data/suzaku/hxd/cpf/ae_hxd_pinhxnome${rsp_index}*.rsp))
    rsp_file=${_rsp_tmps[-1]}
    _rsp_flat_tmps=($(ls $CALDB/data/suzaku/hxd/cpf/ae_hxd_pinflate${rsp_index}*.rsp))
    rsp_flat_file=${_rsp_flat_tmps[-1]}

    rm -f hxd__src.rmf hxd__flat.rmf
    ln -s ${rsp_file} hxd__src.rmf
    ln -s ${rsp_flat_file} hxd__flat.rmf

    ## merge gti
    gti_file=tmp_pin.gti
    rm $gti_file -f &&
        mgtime ingtis="${pin_file}+2,tmp_nxb.evt+2" \
            outgti=$gti_file merge="AND"
done
cd $My_Suzaku_D
# _SuzakuHxdGso_2_products
## obtain spectrum, rmf and arf, and do corrections
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
else 
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
fi
cd $My_Suzaku_D
nxb_evt=ae_hxdGso_nxb.evt

function _mjd2date() {
    if (($# == 0)); then
        args=$(cat /dev/stdin)
    else
        args=$@
    fi
    date_strings=($args)
    for mjd_str in ${args[@]}; do
        mjd_tmp=$(echo ${mjd_str} | sed s/^.*([0-9]+).*$/\1/)
        val_n=$(($mjd_tmp + 678881))
        val_a1=$((4 * ($val_n + 1) / 146097 + 1))
        val_a2=$((3 * $val_a1 / 4))
        val_a=$((4 * $val_n + 3 + 4 * $val_a2))
        val_b1=$(($val_a % 1461 / 4))
        val_b=$((5 * $val_b1 + 2))
        y=$(($val_a / 1461))
        m=$(($val_b / 153 + 3))
        d=$(($val_b % 153 / 5 + 1))
        if [[ $m -ge 13 ]]; then
            y=$(($y + 1))
            m=$(($m - 12))
        fi
        echo "$y-$m-$d"
    done
}

function _Obtain_SuzakuHxdGso_NxbEvt() {
    mjd_str=$1
    date_str=$(_mjd2date $mjd_str)
    date_list=(${date_str//-/ })
    y=$(echo ${date_list[0]} | sed s/^.*([0-9]+).*$/\1/)
    m=$(echo ${date_list[1]} | sed s/^.*([0-9]+).*$/\1/ | printf "%02i" $(cat))
    if [[ $mjd_str -ge 55868 ]]; then # 2011-11-03
        version=2.6
    else
        version=2.5
    fi
    # data.darts.isas.jaxa.jpとwww.astro.isas.jaxa.jpのどっち使うべき?
    url="https://data.darts.isas.jaxa.jp/pub/suzaku/background/hxd/gsonxb/gsonxb_ver${version}/${y}_${m}/ae${My_Suzaku_ID}_hxd_gsobgd.evt.gz"
    #url="http://www.astro.isas.jaxa.jp/suzaku/analysis/hxd/pinnxb/pinnxb_ver${version}_tuned/${y}_${m}/ae${My_Suzaku_ID}_hxd_pinbgd.evt.gz"
    wget $url --no-check-certificate -O ${nxb_evt}
}

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do
    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
    if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

    cd $My_Suzaku_Dir
    _gso_tmps=($(find . -name "ae${My_Suzaku_ID}hxd_0_gsono_cl.evt*" -printf "%f\n"))
    gso_file=${_gso_tmps[0]}
    _pse_tmps=($(find . -name "ae${My_Suzaku_ID}hxd_0_pse_cl.evt*" -printf "%f\n"))
    pse_file=${_pse_tmps[0]}
    _gsoDat_tmps=($(find ${CALDB}/data/suzaku/hxd/cpf/ -name "gsobgd64bins.dat" -printf "%p\n"))
    gsoDat_file=${_gsoDat_tmps[0]}
    gsoDat_url="https://heasarc.gsfc.nasa.gov/docs/suzaku/analysis/gsobgd64bins.dat"
    if [[ ! -r ${gsoDat_file} ]]; then
        gsoDat_file=${gsoDat_url##*/}
        wget $gsoDat_url --no-check-certificate -O ${gsoDat_file}
    fi

    hxdgsoxbpi input_fname=${gso_file} \
        pse_event_fname=${pse_file} \
        bkg_event_fname=${nxb_evt} \
        outstem=tmp_ \
        gsonom_rsp=CALDB \
        groupspec=yes \
        groupfile=${gsoDat_file}
    rsp_file=($(find . "ae_hxd_gsohxnom_*.rsp" -printf "%f\n"))
    ln -s $rsp_file hxdGso__rmf.fits
    arf_file="${CALDB}/data/suzaku/hxd/cpf/ae_hxd_gsoxinom_crab_20100526.arf"
    ln -s $arf_file hxdGso__arf.fits

    declare -A rename_dic=(
        ["tmp_hxd_gso_sr.pi"]=hxdGso__nongrp.fits
        ["tmp_hxd_gso_sr_grp.pi"]=hxdGso__grpauto.fits
        ["tmp_hxd_gso_nxb.pi"]=hxdGso__bkg.fits
        )
    for oldName in ${!rename_dic[@]}; do
        mv -f $oldName ${rename_dic[$oldName]}
    done
    rm ${My_Suzaku_Dir}/fitGso -rf
    mkdir ${My_Suzaku_Dir}/fitGso -p
    mv -f hxdGso__* ${My_Suzaku_Dir}/fitGso

done
cd $My_Suzaku_D
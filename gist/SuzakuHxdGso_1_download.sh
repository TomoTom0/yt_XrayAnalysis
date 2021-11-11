# _SuzakuHxdGso_1_download
## download NXB (Non X-ray Background source) and other files for Suzaku HXD GSO
declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
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
    url="https://data.darts.isas.jaxa.jp/pub/suzaku/background/hxd/gsonxb/gsonxb_ver${version}/${y}_${m}/ae${My_Suzaku_ID}_hxd_gsobgd.evt.gz"
    #url="http://www.astro.isas.jaxa.jp/suzaku/analysis/hxd/pinnxb/pinnxb_ver${version}_tuned/${y}_${m}/ae${My_Suzaku_ID}_hxd_pinbgd.evt.gz"
    wget $url --no-check-certificate -O ${nxb_evt}
}

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Suzaku_ID in ${obs_dirs[@]}; do
    My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
    if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

    cd $My_Suzaku_Dir
    if [[ -r ${nxb_evt} && ${FLAG_canSkip:=false} == true ]]; then continue; fi

    _gso_tmps=($(find . -name "ae${My_Suzaku_ID}hxd_0_gsono_cl.evt*" -printf "%f\n"))
    gso_file=${_gso_tmps[0]}
    obs_MJD_tmp_float=($(fkeyprint infile="${gso_file}" keynam="MJD-OBS" |
        grep "MJD-OBS\s*=" |
        sed -r -n "s/^.*MJD-OBS\s*=\s*(.*)\s*\/.*$/\1/p"))
    obs_MJD=$(printf "%.0f" ${obs_MJD_tmp_float[0]})
    _Obtain_SuzakuHxdGso_NxbEvt $obs_MJD
    # ${nxb_evt}
done
gso_urls=(
    "https://heasarc.gsfc.nasa.gov/docs/suzaku/analysis/gsobgd64bins.dat"
    "http://www.astro.isas.jaxa.jp/suzaku/analysis/hxd/gsoarf2/arf/ae_hxd_gsoxinom_crab_20100526.arf"
    "http://www.astro.isas.jaxa.jp/suzaku/analysis/hxd/gsoarf2/arf/ae_hxd_gsohxnom_crab_20100526.arf")
cpf_path="${CALDB}/data/suzaku/hxd/cpf/"
for gso_url in ${gso_urls[@]}; do
    if [[ ! -r ${cpf_path}/${gso_url##*/} ]];then
        wget $gso_url --no-check-certificate -P $cpf_path
    fi
done
cd $My_Suzaku_D
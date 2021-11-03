# _SuzakuHxd_1_obtainNxb
## download NXB (Non X-ray Background source)
declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
cd $My_Suzaku_D

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

function _Obtain_SuzakuHxd_NxbPha() {
    mjd_str=$1
    date_str=$(_mjd2date $mjd_str)
    date_list=(${date_str//-/ })
    y=$(echo ${date_list[0]} | sed s/^.*([0-9]+).*$/\1/)
    m=$(echo ${date_list[1]} | sed s/^.*([0-9]+).*$/\1/ | printf "%02i" $(cat))
    if [[ $mjd_str -ge 56139 ]]; then
        version=2.2
    else
        version=2.0
    fi
    url="http://www.astro.isas.jaxa.jp/suzaku/analysis/hxd/pinnxb/pinnxb_ver${version}_tuned/${y}_${m}/ae${My_Suzaku_ID}_hxd_pinbgd.evt.gz"
    wget $url -O tmp_nxb.evt
}

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
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
    _Obtain_SuzakuHxd_NxbPha $obs_MJD
    # tmp_nxb.evt
done
cd $My_Suzaku_D
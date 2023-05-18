# _SwiftXrt_4_obtainRmf
## obtain rmf
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Swift_D=${My_Swift_D:=$(pwd)} 
else 
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
fi # 未定義時に代入
cd $My_Swift_D
function _ObtainXrtRmfVersion() {
    mjd_in=$1

    boundaries=(53339 54101 54343 54832 55562 56292)
    values=(None s0_20010101v012 s0_20070101v012 s6_20010101v014 s6_20090101v014 s6_20110101v014 s6_20130101v014)
    ind_val=0
    for bound in ${boundaries[@]}; do
        if [[ ! $mjd_in =~ [0-9]+ || $mjd_in -le $bound ]]; then
            break
        fi
        ind_val=$(($ind_val + 1))
    done
    echo ${values[$ind_val]}
}

function _ObtainXrtRmfGrade() {
    grade_in=$1

    if [[ "x$grade_in" == "x0:12" ]]; then
        echo 0to12
    elif [[ "x$grade_in" == "x0:4" ]]; then
        echo 0to4
    else
        echo 0
    fi
}

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir/xrt/output/fit ]]; then continue; fi

    cd $My_Swift_Dir/xrt/output/fit
    pha_file=xrt__nongrp.fits
    keyName="MJD-OBS"
    obs_MJD_tmp_float=($(fkeyprint infile="${pha_file}" keynam="${keyName}" |
        grep "${keyName}\s*=" |
        sed -r -n "s/^.*${keyName}\s*=\s*(.*)\s*\/.*$/\1/p"))
    obs_MJD=$(printf "%.0f" ${obs_MJD_tmp_float[0]})

    rmf_version=$(_ObtainXrtRmfVersion $obs_MJD)

    if [[ "x${rmf_version:-None}" == "xNone" ]]; then
        echo "Error occured in rmf copy"
        kill -INT $$
    fi

    keyName=DSVAL1
    grade_tmp=($(fkeyprint infile="${pha_file}" keynam="${keyName}" |
        grep "${keyName}\s*=" |
        sed -r -n "s/^.*${keyName}\s*=\s*(.*)\s*\/.*$/\1/p"))
    grade=$(echo ${grade_tmp[0]} | sed -r -n "s/^[^0-9]*(0[0-9:]*).*$/\1/gp")
    rmf_grade=$(_ObtainXrtRmfGrade $grade)

    _rmf_tmps=($(find ${CALDB}/data/swift/xrt/cpf/rmf/ -name "swxpc${rmf_grade}${rmf_version}.rmf"))
    rmf_file=${_rmf_tmps[0]}
    rm -f xrt__rmf.fits && ln -s $rmf_file xrt__rmf.fits
done
cd $My_Swift_D
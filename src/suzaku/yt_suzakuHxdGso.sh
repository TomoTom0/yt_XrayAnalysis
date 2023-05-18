#!/bin/bash

alias yt_suzakuHxdGso_1="_SuzakuHxdGso_1_download"
alias yt_suzakuHxdGso_download="_SuzakuHxdGso_1_download"
function _SuzakuHxdGso_1_download() {
    ## download NXB (Non X-ray Background source) and other files for Suzaku HXD GSO
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    download NXB event file from jaxa for Suzaku HXD GSO


Options
--canSkip
    If the NXB event file exists, downloading will be skipped or not.
    DEFAULT: no

-h,--help
    show this message


EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--canSkip"]="canSkip"
    )
    declare -A flagsArgDict=(
    )

    # arguments variables
    declare -i argc=0
    declare -A kwargs=()
    declare -A flagsIn=()

    declare -a allArgs=($@)

    __obtain_options allArgs flagsAll flagsArgDict argc kwargs flagsIn

    if [[ " ${!flagsIn[@]} " =~ " help " ]]; then
        __usage
        return 0
    fi

    # ---------------------
    ##         main
    # ---------------------
    FLAG_canSkip=false
    if [[ x${FUNCNAME} == x ]]; then
        if [[ -n "${flagsIn[canSkip]}" ]]; then
            FLAG_canSkip=true
        fi
    fi
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
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuHxdGso_2="_SuzakuHxdGso_2_products"
alias yt_suzakuHxdGso_products="_SuzakuHxdGso_2_products"
function _SuzakuHxdGso_2_products() {
    ## obtain spectrum, rmf and arf, and do corrections
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    obtain spectrum, rmf and arf, and do corrections


Options
-h,--help
    show this message


EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--canSkip"]="canSkip"
    )
    declare -A flagsArgDict=(
    )

    # arguments variables
    declare -i argc=0
    declare -A kwargs=()
    declare -A flagsIn=()

    declare -a allArgs=($@)

    __obtain_options allArgs flagsAll flagsArgDict argc kwargs flagsIn

    if [[ " ${!flagsIn[@]} " =~ " help " ]]; then
        __usage
        return 0
    fi

    # ---------------------
    ##         main
    # ---------------------
    FLAG_canSkip=false
    if [[ x${FUNCNAME} == x ]]; then
        if [[ -n "${flagsIn[canSkip]}" ]]; then
            FLAG_canSkip=true
        fi
    fi
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
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}


alias yt_suzakuHxdGso_3="_SuzakuHxdGso_3_editHeader"
alias yt_suzakuHxdGso_editHeader="_SuzakuHxdGso_3_editHeader"
function _SuzakuHxdGso_3_editHeader() {
    ## edit header

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        cat <<EOF
Usage: ${FUNCNAME[1]} [-h,--help] [--minimum] [--strict] ...

${FUNCNAME[1]}
    add the file names of bkg, rmf and arf for Xspec to fits header.


Options
-h,--help
    show this message

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
    )
    declare -A flagsArgDict=(
    )

    # arguments variables
    declare -i argc=0
    declare -A kwargs=()
    declare -A flagsIn=()

    declare -a allArgs=($@)

    __obtain_options allArgs flagsAll flagsArgDict argc kwargs flagsIn

    if [[ " ${!flagsIn[@]} " =~ " help " ]]; then
        __usage
        return 0
    fi

    # ---------------------
    ##         main
    # ---------------------

    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    else 
        declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    fi
    cd $My_Suzaku_D
    function _ObtainExtNum(){
        tmp_fits="$1"
        extName="${2:-SPECTRUM}"
        if [[ -n "${tmp_fits}" ]]; then
            _tmp_extNums=($(fkeyprint infile=$tmp_fits keynam=EXTNAME |
                grep -B 1 $extName |
                sed -r -n "s/^.*#\s*EXTENSION:\s*([0-9]+)\s*$/\1/p"))
        else
            _tmp_extNums=(0)
        fi
        echo ${_tmp_extNums[0]:-0}
    }
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir/fitGso ]]; then continue; fi

        cd $My_Suzaku_Dir/fitGso
        find . -name "hxdGso__*" | rename -f "s/hxdGso__/hxdGso_${My_Suzaku_ID}_/"
        for nongrp_name in $(find . -name "hxdGso_[0-9]*_nongrp.fits" -printf "%f\n"); do
            grp_name=${nongrp_name/_nongrp.fits/_grp${grp_num}.fits}
            nongrpExtNum=$(_ObtainExtNum $nongrp_name SPECTRUM)
            declare -A tr_keys=(
                ["RESPFILE"]=hxdGso_${My_Suzaku_ID}_rmf.fits
                ["BACKFILE"]=hxdGso_${My_Suzaku_ID}_bkg.fits
                ["ANCRFILE"]=hxdGso_${My_Suzaku_ID}_arf.fits)

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile="${nongrp_name}+${nongrpExtNum}" \
                    keyword="${key}" add=yes
            done

        done

    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuHxdGso_4="_SuzakuHxdGso_4_grppha"
alias yt_suzakuHxdGso_grppha="_SuzakuHxdGso_4_grppha"
function _SuzakuHxdGso_4_grppha() {
    ## grppha
    # args: gnum=25

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        cat <<EOF
Usage: ${FUNCNAME[1]} [-h,--help] [--gnum GNUM] ...

${FUNCNAME[1]}
    do grouping with grppha
    In default, this function uses "group min GNUM" for grouping
    If gnum for a camera is less than or equal to 0, then the grouping will be skipped.


Options
--gnum GNUM
    change gnum for HXD/GSO


EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--gnum"]="gnum"
    )
    declare -A flagsArgDict=(
        ["gnum"]="gnum"
    )

    # arguments variables
    declare -i argc=0
    declare -A kwargs=()
    declare -A flagsIn=()

    declare -a allArgs=($@)

    __obtain_options allArgs flagsAll flagsArgDict argc kwargs flagsIn

    if [[ " ${!flagsIn[@]} " =~ " help " ]]; then
        __usage
        return 0
    fi

    # ---------------------
    ##         main
    # ---------------------
    declare -A gnum=25
    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${kwargs[gnum__gnum]} ]]; then
            declare -i gnum=${kwargs[gnum__gnum]}
        fi
    fi

    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    else 
        declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    fi
    cd $My_Suzaku_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl
        if [[ ! -r $My_Suzaku_Dir/fitGso ]]; then continue; fi

        cd $My_Suzaku_Dir/fitGso
        for nongrp_name in $(find . -name "hxdGso_[0-9]*_nongrp.fits" -printf "%f\n"); do
            grp_name=${nongrp_name/_nongrp.fits/_grp${gnum}.fits}

            rm $grp_name -f
            cat <<EOF | bash
grppha infile=${nongrp_name} outfile=${grp_name}
group min ${gnum}
exit !${grp_name}
EOF

        done
    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuHxdGso_5="_SuzakuHxdGso_5_fitDirectory"
alias yt_suzakuHxdGso_fitDirectory="_SuzakuHxdGso_5_fitDirectory"
function _SuzakuHxdGso_5_fitDirectory() {
    ##    to fit directory
    # args: FLAG_hardCopy=false
    # args: FLAG_symbLink=false
    # args: tmp_prefix="hxdGso_"

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        cat <<EOF
Usage: ${FUNCNAME[1]} [-h,--help] [--hardCopy] [--symbLink] ...

${FUNCNAME[1]}
    move files to fit directory
    This process has two steps:
        1. copy files to ./fit
        2. generate symbolic link to ../fit


Options
-h,--help
    show this message

--hardCopy
    hard copy instead of generating symbolic link to $(../fit) (Step 2.)

--symbLink
    generate symbolic link instead of copy to $(./fit) (Step 1.)

--prefixName prefixName
    select the prefix of file names to move

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--hardCopy"]="hardCopy"
        ["--symbLink"]="symbLink"
        ["--prefixName"]="prefixName"
    )
    declare -A flagsArgDict=(
        ["prefixName"]="name"
    )

    # arguments variables
    declare -i argc=0
    declare -A kwargs=()
    declare -A flagsIn=()

    declare -a allArgs=($@)

    __obtain_options allArgs flagsAll flagsArgDict argc kwargs flagsIn

    if [[ " ${!flagsIn[@]} " =~ " help " ]]; then
        __usage
        return 0
    fi

    # ---------------------
    ##         main
    # ---------------------
    FLAG_hardCopy=false
    FLAG_symbLink=false
    tmp_prefix="hxdGso_"
    if [[ x${FUNCNAME} == x ]]; then
        if [[ -n "${flagsIn[hardCopy]}" ]]; then
            FLAG_hardCopy=true
        fi
        if [[ -n "${flagsIn[symbLink]}" ]]; then
            FLAG_symbLink=true
        fi
        if [[ -n "${kwargs[prefixName__name]}" ]]; then
            tmp_prefix=${kwargs[prefixName__name]}
        fi
    fi
    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    else 
        declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
    fi
    cd $My_Suzaku_D

    mkdir -p $My_Suzaku_D/fit $My_Suzaku_D/../fit
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        if [[ ${FLAG_symbLink:=false} == "true" ]]; then
            find $My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl/fitGso/ -name "${tmp_prefix}*.*" \
                -type f -printf "%f\n" |
                xargs -n 1 -i rm -f $My_Suzaku_D/fit/{}
            ln -s $My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl/fitGso/${tmp_prefix}* ${My_Suzaku_D}/fit/
        else
            cp -f $My_Suzaku_D/$My_Suzaku_ID/hxd/event_cl/fitGso/${tmp_prefix}* ${My_Suzaku_D}/fit/
        fi
    done
    if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
        cp -f $My_Suzaku_D/fit/${tmp_prefix}*.* $My_Suzaku_D/../fit/
    else
            # remove the files with the same name as new files
        find $My_Suzaku_D/fit/ -name "${tmp_prefix}*.*" \
            -type f -printf "%f\n" |
            xargs -n 1 -i rm -f $My_Suzaku_D/../fit/{}
        # generate symbolic links
        ln -s $My_Suzaku_D/fit/${tmp_prefix}*.* $My_Suzaku_D/../fit/
    fi
    # remove broken symbolic links
    find -L $My_Suzaku_D/../fit/ -type l -delete

    cd $My_Suzaku_D

    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}


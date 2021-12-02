#!/bin/bash

dir_path=$(
    cd $(dirname ${BASH_SOURCE:-$0})
    pwd
)
source ${dir_path}/../../lib/obtain_options.sh

alias yt_newton_1="_Newton_1_pipeline"
alias yt_newton_pipeline="_Newton_1_pipeline"
function _Newton_1_pipeline() {
    ## はじめの処理
    # args: all_cams=(mos1 mos2 pn)
    # args: FLAG_clean=false

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--ignore mos1,mos2,pn]" 1>&2
        cat <<EOF

${FUNCNAME[1]}
    execute first pipeline for EMOS and EPN


Options
--ignore mos1,mos2,pn
    skip the process of selected cameras

--clean
    clean "fit/*"

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--ignore"]="ignore"
        ["--clean"]="clean"
    )
    declare -A flagsArgDict=(
        ["ignore"]="cameras"
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
    all_cams=(mos1 mos2 pn)
    FLAG_clean=false
    if [[ "x${FUNCNAME}" != x ]]; then
        if [[ -n ${kwargs[ignore__cameras]} ]]; then
            all_cams=$(echo ${kwargs[ignore__cameras]} | grep -o -E "(mos1|mos2|pn)")
        fi
        if [[ -n ${flagsIn[clean]} ]]; then
            FLAG_clean=true
        fi
    fi

    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    cd $My_Newton_D

    if [[ x == "x$(alias sas 2>/dev/null)" ]]; then
        echo "Error: alias sas is not defined."
        kill -INT $$
    fi
    sas
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Newton_ID in ${obs_dirs[@]}; do
        My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
        if [[ ! -r $My_Newton_Dir ]]; then continue; fi
        cd $My_Newton_Dir

        find . -name "*.gz" | xargs gunzip
        export SAS_ODF=$My_Newton_D/$My_Newton_ID/ODF &&
            rm ccf.cif *SUM.SAS -f && cifbuild # make ccf.cif
        if [[ ! -r ccf.cif ]]; then
            echo "Error occured in cifbuild"
            kill -INT $$
        fi
        export SAS_CCF=$My_Newton_Dir/ccf.cif &&
            rm *SUM.SAS -f && odfingest # make *SUM.SAS
        if [[ x == x$(find . -name "*SUM.SAS" -printf 1) ]]; then
            echo "Error occured in odfingest"
            kill -INT $$
        fi
        _SAS_ODF_tmps=($(ls $My_Newton_Dir/*SUM.SAS))
        export SAS_ODF=${_SAS_ODF_tmps[-1]}
        rm -f *_EMOS[12]_*_ImagingEvts.ds && emproc
        if [[ x11 != x$(find . -name "*_EMOS[12]_*_ImagingEvts.ds" -printf 1) ]]; then
            echo "Error occured in emproc"
            kill -INT $$
        fi
        rm -f *_EPN_*_ImagingEvts.ds && epproc
        if [[ x == x$(find . -name "*_EPN_*_ImagingEvts.ds" -printf 1) ]]; then
            echo "Error occured in epproc"
            kill -INT $$
        fi
        if [[ "${FLAG_clean:=false}" == "true" ]]; then
            rm $My_Newton_Dir/fit -rf
        fi
        mkdir $My_Newton_Dir/fit -p

        cp *_EMOS1_*_ImagingEvts.ds fit/mos1.fits -f
        cp *_EMOS2_*_ImagingEvts.ds fit/mos2.fits -f
        cp *_EPN_*_ImagingEvts.ds fit/pn.fits -f

    done
    cd $My_Newton_D

    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_newton_2="_Newton_2_filter"
alias yt_newton_filter="_Newton_2_filter"
function _Newton_2_filter() {
    ## evselectでfiterをかけたfits作成
    # args: declare -A pis=(["mos1"]="PI in [200:12000]" ["mos2"]="PI in [200:12000]" ["pn"]="PI in [200:15000]")
    # args: declare -A pis_hard=(["mos1"]="PI > 10000" ["mos2"]="PI > 10000" ["pn"]="PI in [10000:12000]")
    # args: declare -A rates=(["mos1"]=0.35 ["mos2"]=0.35 ["pn"]=0.4)

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--filter FILTER_MOS1,MOS2,PN] ..." 1>&2
        cat <<EOF

${FUNCNAME[1]}
    filter with Counts in order to remove flare


Options
--filter FILTER_FOR_MOS1,FILTER_FOR_MOS2,FILTER_FOR_PN
    first filter about energy bands

--filterHard FILTER_FOR_MOS1,FILTER_FOR_MOS2,FILTER_FOR_PN
    filter about energy bands in order to find hard flare

--filterRates FILTER_FOR_MOS1,FILTER_FOR_MOS2,FILTER_FOR_PN
    filter about rates in order to make gti

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--filter"]="filter"
        ["--filterHard"]="filterHard"
        ["--filterRates"]="filterRates"
    )
    declare -A flagsArgDict=(
        ["filter"]="filters"
        ["filterHard"]="filters"
        ["filterRates"]="filters"
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
        return 0
    fi

    # ---------------------
    ##         main
    # ---------------------
    declare -A pis=(["mos1"]="PI in [200:12000]" ["mos2"]="PI in [200:12000]" ["pn"]="PI in [200:15000]")
    declare -A pis_hard=(["mos1"]="PI > 10000" ["mos2"]="PI > 10000" ["pn"]="PI in [10000:12000]")
    declare -A rates=(["mos1"]=0.35 ["mos2"]=0.35 ["pn"]=0.4)
    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${kwargs[filter__filters]} ]]; then
            if [[ "x${tmp_filter^^}" == "xNONE" ]]; then
                tmp_filter=("PI > 0" "PI > 0" "PI > 0")
            else
                tmp_filter=(${kwargs[filter__filters]//,/ })
            fi
            declare -A pis=(["mos1"]="${tmp_filter[0]}" ["mos2"]="${tmp_filter[1]}" ["pn"]="${tmp_filter[2]}")
        fi
        if [[ -n ${kwargs[filterHard__filters]} ]]; then
            if [[ "x${tmp_filter^^}" == "xNONE" ]]; then
                tmp_filter=("PI > 0" "PI > 0" "PI > 0")
            else
                tmp_filter=(${kwargs[filterHard__filters]//,/ })
            fi
            declare -A pis_hard=(["mos1"]="${tmp_filter[0]}" ["mos2"]="${tmp_filter[1]}" ["pn"]="${tmp_filter[2]}")
        fi
        if [[ -n ${kwargs[filterRates__filters]} ]]; then
            if [[ "x${tmp_filter^^}" == "xNONE" ]]; then
                tmp_filter=("1e10" "1e10" "1e10")
            else
                tmp_filter=(${kwargs[filterRates__filters]//,/ })
            fi
            declare -A rates=(["mos1"]="${tmp_filter[0]}" ["mos2"]="${tmp_filter[1]}" ["pn"]="${tmp_filter[2]}")
        fi
    fi

    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    cd $My_Newton_D
    declare -A xmms=(["mos1"]="#XMMEA_EM" ["mos2"]="#XMMEA_EM" ["pn"]="#XMMEA_EP")

    if [[ x == "x$(alias sas 2>/dev/null)" ]]; then
        echo "Error: alias sas is not defined."
        kill -INT $$
    fi
    sas

    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Newton_ID in ${obs_dirs[@]}; do

        My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
        if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
        cd $My_Newton_Dir/fit

        all_cams_tmp=($(find . -name "*.fits" -printf "%f\n" | sed -r -n "s/^(mos1|mos2|pn).fits$/\1/p"))
        for cam in ${all_cams_tmp[@]}; do
            rm tmp_${cam}_filt.fits -f &&
                evselect table=${cam}.fits withfilteredset=yes \
                    expression="(PATTERN <= 12)&&(${pis[$cam]})&&${xmms[$cam]}" \
                    filteredset=tmp_${cam}_filt.fits filtertype=expression \
                    keepfilteroutput=yes \
                    updateexposure=yes filterexposure=yes

            rm tmp_${cam}_lc_hard.fits -f &&
                evselect table=${cam}.fits withrateset=yes \
                    rateset=tmp_${cam}_lc_hard.fits \
                    maketimecolumn=yes timecolumn=TIME timebinsize=100 makeratecolumn=yes \
                    expression="(PATTERN == 0)&&(${pis_hard[$cam]})&&${xmms[$cam]}"

            rm ${cam}_gti.fits -f &&
                tabgtigen table=tmp_${cam}_lc_hard.fits gtiset=${cam}_gti.fits \
                    timecolumn=TIME \
                    expression="(RATE <= ${rates[$cam]})"

            rm ${cam}_filt_time.fits -f &&
                evselect table=tmp_${cam}_filt.fits withfilteredset=yes \
                    expression="gti(${cam}_gti.fits,TIME)" filteredset=${cam}_filt_time.fits \
                    filtertype=expression keepfilteroutput=yes \
                    updateexposure=yes filterexposure=yes
        done

    done
    cd $My_Newton_D

    if [[ x${FUNCNAME} != x ]]; then return 0; fi

}

alias yt_newton_3="_Newton_3_ds9"
alias yt_newton_ds9="_Newton_3_ds9"
function _Newton_3_ds9() {
    ## ds9で領域指定
    # args: FLAG_simple=false

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--simple]" 1>&2
        cat <<EOF

${FUNCNAME[1]}
    make region files about source and background with ds9
    In default, a region file with two circles are automatically loaded, 
    so you have only to adjust the circle and overwrite the region file.


Options
--simple
    In simple mode, you make two circles
    which respectively points the source and background
    and save it as the proper name.

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--simple"]="simple"
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
    FLAG_simple=false
    if [[ x${FUNCNAME} == x ]]; then
        if [[ -n ${flagsIn[simple]} ]]; then
            FLAG_simple=true
        fi
    fi

    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    cd $My_Newton_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Newton_ID in ${obs_dirs[@]}; do

        My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
        if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi

        cd $My_Newton_Dir/fit
        _evt_tmps=($(find $My_Newton_Dir/fit/ -name "*_filt_time.fits" -printf "%f\n"))
        evt_file=${_evt_tmps[0]}
        if [[ ! -r ${My_Newton_D}/saved.reg && "${FLAG_simple:=false}" == false ]]; then
            # saved.regが存在しないなら、新たに作成する
            declare -A tmp_dict=(["RA_OBJ"]="0" ["DEC_OBJ"]="0")
            for key in ${!tmp_dict[@]}; do
                # fits headerから座標を読み取る
                tmp_dict[$key]=$(fkeyprint infile="${evt_file}+1" keynam="${key}" |
                    grep "${key}\s*=" |
                    sed -r -n "s/^.*${key}\s*=\s*(.*)\s*\/.*$/\1/p")
            done
            ra=$(echo ${tmp_dict[RA_OBJ]} |
                sed -r "s/E([\+\-]?[0-9]+)/*10^\1/" |
                sed -r "s/10\^\+?(-?)0*([0-9]+)/10^(\1\2)/" | bc)
            dec=$(echo ${tmp_dict[DEC_OBJ]} |
                sed -r "s/E([\+\-]?[0-9]+)/*10^\1/" |
                sed -r "s/10\^\+?(-?)0*([0-9]+)/10^(\1\2)/" | bc)
            # background circleはとりあえず0.05 degずつずらした点
            ra_bkg=$(echo "$ra + 0.05 " | bc)
            dec_bkg=$(echo "$dec + 0.05 " | bc)
            # 半径はとりあえず0.026 deg = 100 arcsec
            cat <<EOF > ${My_Newton_D}/saved.reg
# Region file format: DS9 version 4.1
global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1
fk5
circle($ra,$dec,0.026)
circle($ra_bkg,$dec_bkg,0.026) # background
EOF
        fi

        for cam in ${all_cams[@]}; do
            if [[ "${FLAG_simple:=false}" == false ]]; then
                cp ${My_Newton_D}/saved.reg ${cam}.reg -f
                echo ""
                echo "----  save as ${cam}.reg with overwriting  ----"
                echo ""
                ds9 $My_Newton_Dir/fit/${cam}_filt_time.fits \
                    -scale log -cmap bb -mode region \
                    -bin factor 16 -regions load ${cam}.reg
                ### adjust mos1.reg, mos2.reg, pn.reg
                cp ${cam}.reg ${My_Newton_D}/saved.reg -f
            else
                # simple mode
                echo ""
                echo "----  save as ${cam}.reg  ----"
                echo ""
                ds9 $My_Newton_Dir/fit/${cam}_filt_time.fits \
                    -scale log -cmap bb -mode region \
                    -bin factor 16 -regions
                ### make mos1.reg, mos2.reg, pn.reg

            fi
        done
    done
    cd $My_Newton_D

    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_newton_4="_Newton_4_regionFilter"
alias yt_newton_regionFilter="_Newton_4_regionFilter"
function _Newton_4_regionFilter() {
    ## region filter
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat <<EOF

${FUNCNAME[1]}
    filter region and extract spectrum


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

    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    cd $My_Newton_D

    declare -A spchmax=(["mos1"]=11999 ["mos2"]=11999 ["pn"]=20479)

    if [[ x == "x$(alias sas 2>/dev/null)" ]]; then
        echo "Error: alias sas is not defined."
        kill -INT $$
    fi
    sas
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Newton_ID in ${obs_dirs[@]}; do

        My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
        if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
        cd $My_Newton_Dir/fit

        all_cams_tmp=($(find . -name "*_filt_time.fits" -printf "%f\n" |
            sed -r -n "s/^(mos1|mos2|pn)_filt_time.fits$/\1/p"))
        for cam in ${all_cams_tmp[@]}; do
            # for source
            ds9 ${cam}_filt_time.fits -regions load ${cam}.reg -regions system physical \
                -regions centroid -regions save tmp.reg -exit &&
                coor_arg=$(cat tmp.reg | grep circle |
                    grep -v "# background" |
                    sed -r -n "s/^.*circle\((.*)\).*$/\1/p") &&
                rm ${cam}__nongrp.fits ${cam}_filtered.fits  -f &&
                evselect table=${cam}_filt_time.fits energycolumn="PI" \
                    withfilteredset=yes filteredset=${cam}_filtered.fits \
                    keepfilteroutput=yes filtertype="expression" \
                    expression="((X,Y) in CIRCLE(${coor_arg}))" \
                    withspectrumset=yes spectrumset=${cam}__nongrp.fits \
                    spectralbinsize=5 withspecranges=yes \
                    specchannelmin=0 specchannelmax=${spchmax[$cam]}

            # for background
            ds9 ${cam}_filt_time.fits -regions load ${cam}.reg \
                -regions system physical \
                -regions save tmp.reg -exit &&
                coor_arg=$(cat tmp.reg | grep circle |
                    grep "# background" |
                    sed -r -n "s/^.*circle\((.*)\).*$/\1/p") &&
                rm ${cam}__bkg.fits ${cam}_bkg_filtered.fits  -f &&
                evselect table=${cam}_filt_time.fits energycolumn="PI" \
                    withfilteredset=yes filteredset=${cam}_bkg_filtered.fits \
                    keepfilteroutput=yes filtertype="expression" \
                    expression="((X,Y) in CIRCLE(${coor_arg}))" \
                    withspectrumset=yes spectrumset=${cam}__bkg.fits \
                    spectralbinsize=5 withspecranges=yes \
                    specchannelmin=0 specchannelmax=${spchmax[$cam]}
            # FLAG==0 && -> rmfgenでsegmentation error
            export SAS_CCF=$My_Newton_Dir/ccf.cif
            if [[ ! -r "${SAS_CCF}" ]]; then continue ; fi
            backscale spectrumset=${cam}__nongrp.fits badpixlocation=${cam}_filt_time.fits
            backscale spectrumset=${cam}__bkg.fits badpixlocation=${cam}_filt_time.fits
        done
    done
    cd $My_Newton_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_newton_5="_Newton_5_lightCurve"
alias yt_newton_lightCurve="_Newton_5_lightCurve"
function _Newton_5_lightCurve() {
    ## light curve
    # args: declare -A pis=(["mos1"]="PI in [200:12000]" ["mos2"]="PI in [200:12000]" ["pn"]="PI in [200:15000]")
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--filterLc FILTER_MOS1,MOS2,PN]" 1>&2
        cat <<EOF

${FUNCNAME[1]}
    make light curve


Options
--filterLc FILTER_FOR_MOS1,FILTER_FOR_MOS2,FILTER_FOR_PN
    first filter about energy bands

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--filterLc"]="filter"
    )
    declare -A flagsArgDict=(
        ["filter"]="filters"
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

    declare -A pis=(["mos1"]="PI in [200:12000]" ["mos2"]="PI in [200:12000]" ["pn"]="PI in [200:15000]")
    if [[ x${FUNCNAME} == x ]]; then
        if [[ -n ${kwargs[filter__filters]} ]]; then
            tmp_filter=(${kwargs[filter__filters]//,/ })
            declare -A pis=(["mos1"]="${tmp_filter[0]}" ["mos2"]="${tmp_filter[1]}" ["pn"]="${tmp_filter[2]}")
        fi
    fi

    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    cd $My_Newton_D

    if [[ x == "x$(alias sas 2>/dev/null)" ]]; then
        echo "Error: alias sas is not defined."
        kill -INT $$
    fi
    sas
    mkdir $My_Newton_D/lc -p
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Newton_ID in ${obs_dirs[@]}; do

        My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF

        cd $My_Newton_Dir/fit
        all_cams_tmp=($(find . -name "*_filt_time.fits" -printf "%f\n" |
            sed -r -n "s/^(mos1|mos2|pn)_filt_time.fits$/\1/p"))
        for cam in ${all_cams_tmp[@]}; do
            ds9 ${cam}_filt_time.fits -regions load ${cam}.reg \
                -regions system physical -regions save tmp.reg -exit
            coor_arg=$(cat tmp.reg | grep circle |
                grep -v "# background" |
                sed -r -n "s/^.*circle\((.*)\).*$/\1/p")

            evselect table=${cam}_filt_time.fits withrateset=yes \
                rateset=${My_Newton_Dir}/fit/newton_${cam}_${My_Newton_ID}_lc_src.fits \
                maketimecolumn=yes timecolumn=TIME \
                timebinsize=100 makeratecolumn=yes \
                expression="((X,Y) in CIRCLE(${coor_arg}))&&(${pis[$cam]})"
        done
    done
    cd $My_Newton_D

    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_newton_6="_Newton_6_genRmfArf"
alias yt_newton_genRmfArf="_Newton_6_genRmfArf"
function _Newton_6_genRmfArf() {
    ## rmf, arf作成
    # args: FLAG_rmf=true
    # args: FLAG_arf=true

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--rmf] [--arf]" 1>&2
        cat <<EOF

${FUNCNAME[1]}
    generate rmf and arf files


Options
--rmf
    only generate rmf

--arf
    only generate arf

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--rmf"]="rmf"
        ["--arf"]="arf"
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
    FLAG_rmf=true
    FLAG_arf=true
    if [[ x${FUNCNAME} == x ]]; then
        if [[ -n ${flagsIn[rmf]} && -z ${flagsIn[arf]} ]]; then
            FLAG_arf=false
        elif [[ -z ${flagsIn[rmf]} && -n ${flagsIn[arf]} ]]; then
            FLAG_arf=false
        fi
    fi

    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    cd $My_Newton_D

    if [[ x == "x$(alias sas 2>/dev/null)" ]]; then
        echo "Error: alias sas is not defined."
        kill -INT $$
    fi
    sas
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Newton_ID in ${obs_dirs[@]}; do
        My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
        if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
        cd $My_Newton_Dir/fit
        all_cams_now=($(find . -name "*_nongrp.fits" -printf "%f\n" |
            sed -r -n "s/^.*(mos1|mos2|pn).*_nongrp.fits$/\1/p"))

        for cam in ${all_cams_now[@]}; do
            rm ${cam}__rmf.fits ${cam}__arf.fits -f
            export SAS_CCF=$My_Newton_Dir/ccf.cif
            if [[ ! -r "${SAS_CCF}" ]]; then continue ; fi
            #_nongrp_tmps=($(find . -name "*${cam}*_nongrp.fits" -printf "%f\n"))
            #if [[ ${_nongrp_tmps[@]} -eq 0 ]]; then continue; fi
            #nongrp_name=${_nongrp_tmps[0]}
            nongrp_name=${cam}__nongrp.fits
            if [[ "${FLAG_rmf:=true}" == "true" ]]; then
                rm ${cam}__rmf.fits -f &&
                    rmfgen rmfset=${cam}__rmf.fits spectrumset=${nongrp_name}
            fi
            if [[ "${FLAG_arf:=true}" == "true" ]]; then
                #_rmf_tmps=($(find . -name "*${cam}*_rmf.fits" -printf "%f\n"))
                #if [[ ${_rmf_tmps[@]} -eq 0 ]]; then continue; fi
                #rmf_name=${_rmf_tmps[0]}
                rmf_name=${cam}__rmf.fits
                rm ${cam}__arf.fits -f &&
                    arfgen arfset=${cam}__arf.fits spectrumset=${nongrp_name} \
                        withrmfset=yes rmfset=${rmf_name} withbadpixcorr=yes \
                        badpixlocation=${cam}_filt_time.fits
            fi
        done
    done
    cd $My_Newton_D

    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_newton_7="_Newton_7_addascaspec"
alias yt_newton_addascaspec="_Newton_7_addascaspec"
function _Newton_7_addascaspec() {
    ## addascaspec

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat <<EOF

${FUNCNAME[1]}
    combine files EMOS1 and EMOS2 with addascaspec


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
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    cd $My_Newton_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Newton_ID in ${obs_dirs[@]}; do

        My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
        if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
        cd $My_Newton_Dir/fit

        all_cams_now=($(find . -name "*_nongrp.fits" -printf "%f\n" | sed -r -n "s/^.*(mos1|mos2|pn)_.*_nongrp.fits$/\1/p"))
        for cam in ${all_cams_now[@]}; do
            find . -name "${cam}__*.fits" -printf "%f\n" |
                rename -f "s/^${cam}__/newton_${cam}_${My_Newton_ID}_/"
        done

        if [[ " ${all_cams_now[@]} " =~ " mos1 " && " ${all_cams_now[@]} " =~ " mos2 " ]]; then
            mos_cams=($(echo ${all_cams_now[@]//pn/} | sed -r -n "s/\s*(mos1|mos2)\s*/\1 /gp"))
            : >tmp_fi.add
            echo ${mos_cams[@]} | sed -r "s/\s*(mos1|mos2)\s*/newton_\1_${My_Newton_ID}_nongrp.fits /g" >>tmp_fi.add
            echo ${mos_cams[@]} | sed -r "s/\s*(mos1|mos2)\s*/newton_\1_${My_Newton_ID}_bkg.fits /g" >>tmp_fi.add
            echo ${mos_cams[@]} | sed -r "s/\s*(mos1|mos2)\s*/newton_\1_${My_Newton_ID}_rmf.fits /g" >>tmp_fi.add
            echo ${mos_cams[@]} | sed -r "s/\s*(mos1|mos2)\s*/newton_\1_${My_Newton_ID}_arf.fits /g" >>tmp_fi.add

            rm -f newton_mos12_${My_Newton_ID}_nongrp.fits \
                newton_mos12_${My_Newton_ID}_rmf.fits newton_mos12_${My_Newton_ID}_bkg.fits
            addascaspec tmp_fi.add newton_mos12_${My_Newton_ID}_nongrp.fits \
                newton_mos12_${My_Newton_ID}_rmf.fits newton_mos12_${My_Newton_ID}_bkg.fits
        fi
    done

    cd $My_Newton_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_newton_8="_Newton_8_editHeader"
alias yt_newton_editHeader="_Newton_8_editHeader"
function _Newton_8_editHeader() {
    ## edit header
    # args: FLAG_minimum=false
    # args: FLAG_strict=false

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--minimum] [--strict] " 1>&2
        cat <<EOF

${FUNCNAME[1]}
    edit header in order to compensate for losing information with addascaspec
    This function copy information from a original file header to combined one,
    and, at the same time, add the file names of bkg, rmf and arf for Xspec.


Options
--minimum
    not copy but only add the file names of bkg, rmf and arf for Xspec

--strict
    copy information wihch is the completely same values as all the original files.

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--minimun"]="minimum"
        ["--strict"]="strict"
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
    FLAG_minimum=false
    FLAG_strict=false

    if [[ x${FUNCNAME} == x ]]; then
        if [[ -n ${flagsIn[minimum]} ]]; then
            FLAG_minimum=true
        elif [[ -n ${flagsIn[strict]} ]]; then
            FLAG_strict=true
        fi
    fi

    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    cd $My_Newton_D

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
    for My_Newton_ID in ${obs_dirs[@]}; do
        My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
        if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
        cd $My_Newton_Dir/fit

        all_cams_tmp2=($(find . -name "newton_*_nongrp.fits" -printf "%f\n" |
            sed -r -n "s/^newton_(mos1|mos2|mos12|pn)_${My_Newton_ID}_nongrp.fits$/\1/p"))
        for cam in ${all_cams_tmp2[@]}; do
            nongrp_name=newton_${cam}_${My_Newton_ID}_nongrp.fits
            if [[ $cam == "mos12" ]]; then
                # edit header for nongrp
                oldName=newton_mos1_${My_Newton_ID}_nongrp.fits
                newName=$nongrp_name
                oldExtNum=$(_ObtainExtNum $oldName SPECTRUM)
                newExtNum=$(_ObtainExtNum $newName SPECTRUM)


                cp_keys=(LONGSTRN DATAMODE TELESCOP OBS_ID OBS_MODE REVOLUT
                    OBJECT OBSERVER RA_OBJ DEC_OBJ RA_NOM DEC_NOM FILTER ATT_SRC
                    ORB_RCNS TFIT_RPD TFIT_DEG TFIT_RMS TFIT_PFR TFIT_IGH SUBMODE
                    EQUINOX RADECSYS REFXCTYP REFXCRPX REFXCRVL REFXCDLT REFXLMIN
                    REFXLMAX REFXCUNI REFYCTYP REFYCRPX REFYCRVL REFYCDLT
                    REFYLMIN REFYLMAX REFYCUNI AVRG_PNT RA_PNT DEC_PNT PA_PNT)

                cp_keys2=(DATE-OBS DATE-END)

                declare -A tr_keys=(
                    ["INSTRUME"]="EMOS1+EMOS2"
                    ["BACKFILE"]=newton_${cam}_${My_Newton_ID}_bkg.fits
                    ["RESPFILE"]=newton_${cam}_${My_Newton_ID}_rmf.fits
                )
                if [[ ${FLAG_strict:=false} == "true" ]]; then
                    cp_keys2=()
                fi
                if [[ ${FLAG_minimum:=false} == "true" ]]; then
                    cp_keys=()
                    cp_keys2=()
                fi

                for key in ${cp_keys[@]} ${cp_keys2[@]}; do
                    orig_val=$(fkeyprint infile="${oldName}+${oldExtName}" keynam="${key}" |
                        grep "${key}\s*=" |
                        sed -r -n "s/^.*${key}\s*=\s*(.*)\s*\/.*$/\1/p")

                    tr_keys[$key]="${orig_val}"
                done

                for key in ${!tr_keys[@]}; do
                    fparkey value="${tr_keys[$key]}" \
                        fitsfile="${newName}+${newExtName}" \
                        keyword="${key}" add=yes
                done

            else
                # for pn, mos1, mos2
                nongrpExtNum=$(_ObtainExtNum $nongrpName SPECTRUM)
                declare -A tr_keys=(
                    ["BACKFILE"]=newton_${cam}_${My_Newton_ID}_bkg.fits
                    ["RESPFILE"]=newton_${cam}_${My_Newton_ID}_rmf.fits
                    ["ANCRFILE"]=newton_${cam}_${My_Newton_ID}_arf.fits)

                for key in ${!tr_keys[@]}; do
                    fparkey value="${tr_keys[$key]}" \
                        fitsfile="${nongrp_name}+${nongrpExtName}" \
                        keyword="${key}" add=yes
                done
            fi

        done
    done

    cd $My_Newton_D

    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_newton_9="_Newton_9_grppha"
alias yt_newton_grppha="_Newton_9_grppha"
function _Newton_9_grppha() {
    ## grppha
    # args: declare -A gnums=(["pn"]=50 ["mos12"]=50 ["mos1"]=30 ["mos2"]=30)

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--gnumAll GNUM_PN,GNUM_MOS12,GNUM_MOS1,GNUM_MOS2] ..." 1>&2
        cat <<EOF

${FUNCNAME[1]}
    do grouping with grppha
    In default, this function uses "group min GNUM" for grouping
    If gnum for a camera is 0, then the grouping will be skipped.


Options
--gnumAll GNUM_PN,GNUM_MOS12,GNUM_MOS1,GNUM_MOS2
    change gnum for all cameras
    The options "--gnum<Camera>" dominate this option.

--gnumPn GNUM
--gnumMos12 GNUM
--gnumMos1 GNUM
--gnumMos2 GNUM
    change gnum for the selected camera

--gnumZero
    gnums for all cameras are set to 0

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--gnumZero"]="gnumZero"
        ["--gnumAll"]="gnumAll"
        ["--gnumPn"]="gnumPn"
        ["--gnumMos12"]="gnumMos12"
        ["--gnumMos1"]="gnumMos1"
        ["--gnumMos2"]="gnumMos2"
    )
    declare -A flagsArgDict=(
        ["gnumAll"]="gnums"
        ["gnumPn"]="gnum"
        ["gnumMos12"]="gnum"
        ["gnumMos1"]="gnum"
        ["gnumMos2"]="gnum"
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
    declare -A gnums=(["pn"]=50 ["mos12"]=50 ["mos1"]=30 ["mos2"]=30)
    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${flagsIn[gnumZero]} ]]; then
            declare -A gnums=(["pn"]=0 ["mos12"]=0 ["mos1"]=0 ["mos2"]=0)
        fi
        if [[ -n ${kwargs[gnumAll__gnums]} ]]; then
            gnums_tmp=(${kwargs[gnumAll__gnums]//,/ })
            declare -A gnums=(["pn"]=${gnums_tmp[0]:-50} ["mos12"]=${gnums_tmp[1]:-50} ["mos1"]=${gnums_tmp[2]:-30} ["mos2"]=${gnums_tmp[3]:-30})
        fi
        for cam in pn mos12 mos1 mos2; do
            key_tmp=gnum${cam^}__gnum
            if [[ -n ${kwargs[$key_tmp]} ]]; then
                gnums[$cam]=${kwargs[$key_tmp]}
            fi
        done
    fi
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    cd $My_Newton_D

    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Newton_ID in ${obs_dirs[@]}; do
        My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
        if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
        cd $My_Newton_Dir/fit

        all_cams_tmp2=($(find . -name "newton_*_nongrp.fits" -printf "%f\n" |
            sed -r -n "s/^newton_(mos1|mos2|mos12|pn)_${My_Newton_ID}_nongrp.fits$/\1/p"))
        for cam in ${all_cams_tmp2[@]}; do
            gnum=${gnums[$cam]}
            if [[ $gnum -le 0 ]]; then continue; fi
            grp_name=newton_${cam}_${My_Newton_ID}_grp${gnum}.fits
            nongrp_name=newton_${cam}_${My_Newton_ID}_nongrp.fits
            cat <<EOF | bash
grppha infile=$nongrp_name outfile=${grp_name}
group min ${gnum}
exit !${grp_name}
EOF
        done
    done

    cd $My_Newton_D

    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_newton_10="_Newton_10_fitDirectory"
alias yt_newton_fitDirectory="_Newton_10_fitDirectory"
function _Newton_10_fitDirectory() {
    ## fitディレクトリにまとめ
    # args: FLAG_hardCopy=false
    # args: FLAG_symbLink=false
    # args: tmp_prefix="newton_"

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--hardCopy] [--symbLink] ..." 1>&2
        cat <<EOF

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
    tmp_prefix="newton_"

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
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
    cd $My_Newton_D
    mkdir -p $My_Newton_D/fit $My_Newton_D/../fit/
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Newton_ID in ${obs_dirs[@]}; do
        if [[ ${FLAG_symbLink:=false} == "true" ]]; then
            find $My_Newton_D/$My_Newton_ID/ODF/fit/ -name "${tmp_prefix}*.*" \
                -type f -printf "%f\n" |
                xargs -n 1 -i rm -f $My_Newton_D/fit/{}
            ln -s $My_Newton_D/$My_Newton_ID/ODF/fit/${tmp_prefix}* ${My_Newton_D}/fit/
        else
            cp -f $My_Newton_D/$My_Newton_ID/ODF/fit/${tmp_prefix}* ${My_Newton_D}/fit/
        fi
    done
    if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
        cp -f $My_Newton_D/fit/${tmp_prefix}*.* $My_Newton_D/../fit/
    else
            # remove the files with the same name as new files
        find $My_Newton_D/fit/ -name "${tmp_prefix}*.*" \
            -type f -printf "%f\n" |
            xargs -n 1 -i rm -f $My_Newton_D/../fit/{}
        # generate symbolic links
        ln -s $My_Newton_D/fit/${tmp_prefix}*.* $My_Newton_D/../fit/
    fi
    # remove broken symbolic links
    find -L $My_Newton_D/../fit/ -type l -delete

    cd $My_Newton_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

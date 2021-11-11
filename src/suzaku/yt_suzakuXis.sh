#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd)
source ${dir_path}/../../lib/obtain_options.sh

alias yt_suzakuXis_1="_SuzakuXis_1_ds9"
alias yt_suzakuXis_ds9="_SuzakuXis_1_ds9"
function _SuzakuXis_1_ds9() {
    ## ds9
    # args: FLAG_simple=false

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--simple]" 1>&2
        cat << EOF

${FUNCNAME[1]}
    make region files about source and background with ds9
    In default, a region file with two circles are automatically loaded, 
    so you have only to adjust the circle and overwrite the region file.


Options
--simple
    In simple mode, you make two circles
    which respectively points the source and background
    and save it as the proper name.

-h,--help
    show this message

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
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do

        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
        if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi
        cd $My_Suzaku_Dir
        evt_lists=($(ls ae*xi1*3x3*.evt*))
        evt_file=${evt_lists[0]}

        if [[ ! -f ${My_Suzaku_D}/saved.reg && ${FLAG_simple:=false} == false ]]; then
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
            ds9 $evt_file \
                -regions system fk5 \
                -regions command "fk5; circle $ra $dec 0.026 # source" \
                -regions command "fk5; circle $ra_bkg $dec_bkg 0.026 # background" \
                -regions save $My_Suzaku_D/saved.reg -exit
        fi
        if [[ ${FLAG_simple:=false} == false ]]; then
            cp ${My_Suzaku_D}/saved.reg xis.reg -f
            echo ""
            echo "----  save as xis.reg with overwriting  ----"
            echo ""
            ds9 $evt_file \
                -scale log -cmap bb -mode region \
                -regions load xis.reg
            ### adjust xis.reg

            cp xis.reg ${My_Suzaku_D}/saved.reg -f
        else
            echo ""
            echo "----  save as xis.reg  ----"
            echo ""
            ds9 $evt_file \
                -scale log -cmap bb -mode region
        fi

        reg_file=xis.reg
        cat ${reg_file} | grep -v -E "^circle.*# background" >src.reg
        cat ${reg_file} | grep -v -E "^circle.*\)$" >bkg.reg

    done

    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi

}

alias yt_suzakuXis_2="_SuzakuXis_2_xselect"
alias yt_suzakuXis_xselect="_SuzakuXis_2_xselect"
function _SuzakuXis_2_xselect() {
    ## extarct spec with xselect
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat << EOF

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
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do

        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
        if [[ ! -r $My_Suzaku_Dir ]]; then continue; fi

        cd $My_Suzaku_Dir
        rm ${My_Suzaku_Dir}/fit -rf
        mkdir ${My_Suzaku_Dir}/fit -p

        ### obtain all xis cameras
        xis_cams_tmp=($(ls ae${My_Suzaku_ID}xi[0-9]_[0-9]_[0-9]x[0-9]*.evt* |
            sed -r -n "s/^.*(xi[0-9]).*$/\1/p"))
        declare -A arr_tmp
        for cam in "${xis_cams_tmp[@]}"; do arr_tmp[$cam]=""; done
        xis_cams=("${!arr_tmp[@]}")

        for xis_cam in ${xis_cams[@]}; do
            evt_files=($(find . -name "ae${My_Suzaku_ID}${xis_cam}_*.evt*" -printf "%f\n"))
            rm gti.txt bkg.pha src.pi evt.file -f
            if [[ ${#evt_files[@]} == 0 ]]; then
                continue
            elif [[ ${#evt_files[@]} == 1 ]]; then
                evt_file=${evt_files[0]}

                cat <<EOF | bash
xselect
xsel
read event ${evt_file}
./
extract all
filter region src.reg
extract spectrum
save spectrum src.pi
n
clear region
filter region bkg.reg
extract spectrum
save spectrum bkg.pha
n
exit
n
EOF

            else

                evt_first=${evt_files[0]}
                evt_others=$(echo ${evt_files[@]:1} | sed -r "s/(\S+)\s*/read event \1\n/g")
                cat <<EOF | bash
xselect
xsel
read event ${evt_first}
./
${evt_others}
extract all
filter region src.reg
extract spectrum
save spectrum src.pi
n
clear region
filter region bkg.reg
extract spectrum
save spectrum bkg.pha
n
exit
n
EOF
            fi
            mv src.pi ${My_Suzaku_Dir}/fit/${xis_cam}__nongrp.fits -f
            mv bkg.pha ${My_Suzaku_Dir}/fit/${xis_cam}__bkg.fits -f
        done
        cp *.reg ${My_Suzaku_Dir}/fit -f
    done

    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuXis_3="_SuzakuXis_3_genRmfArf"
alias yt_suzakuXis_genRmfArf="_SuzakuXis_3_genRmfArf"
function _SuzakuXis_3_genRmfArf() {
    ## rmfおよびarf作成
    # args: FLAG_rmf=true
    # args: FLAG_arf=true


    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--rmf] [--arf]" 1>&2
        cat << EOF

${FUNCNAME[1]}
    generate rmf and arf files


Options
--rmf
    only generate rmf

--arf
    only generate arf

-h,--help
    show this message

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
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
    ### rmf
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do

        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
        if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi
        cd $My_Suzaku_Dir/fit
        xis_cams=($(find . -name "xi[0-3]__nongrp.fits" -printf "%f\n" |
            sed -r -n "s/^.*(xi[0-3])__.*$/\1/p"))
        for xis_cam in ${xis_cams[@]}; do
            src_file=${xis_cam}__nongrp.fits
            rm ${xis_cam}__rmf.fits -f
            xisrmfgen phafile=$src_file outfile=${xis_cam}__rmf.fits
        done
    done
    cd $My_Suzaku_D

    ### arf
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do

        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
        echo $My_Suzaku_ID
        if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi
        cd $My_Suzaku_Dir/fit
        xis_cams=($(find . -name "xi[0-3]__nongrp.fits" -printf "%f\n" |
            sed -r -n "s/^.*(xi[0-3])__.*$/\1/p"))
        for xis_cam in ${xis_cams[@]}; do
            src_file=${xis_cam}__nongrp.fits

            _att_tmps=($(ls $My_Suzaku_D/$My_Suzaku_ID/auxil/ae*.att*))
            att_file=${_att_tmps[0]}
            _gti_tmps=($(ls $My_Suzaku_D/$My_Suzaku_ID/xis/hk/ae*${xis_cam}_*_conf_uf.gti*))
            gti_file=${_gti_tmps[0]}
            _detmask_tmps=($(ls $CALDB/data/suzaku/xis/bcf/ae_${xis_cam}_calmask*.fits))
            detmask_file=${_detmask_tmps[-1]}

            ra_tmp=$(cat src.reg | grep ^circle | sed 's/circle(\(.*\),.*,.*/\1/')
            if [[ ${ra_tmp} =~ "[0-9]+:[0-9]+:[0-9]+" ]]; then
                ra_li=($(echo ${ra_tmp} | sed "s/:/ /g"))
                ra=$(echo "scale=8; 15 *( ${ra_li[0]} + ${ra_li[1]}/60 + ${ra_li[2]}/3600)" | bc)
            else
                ra=${ra_tmp}
            fi
            dec_tmp=$(cat src.reg | grep ^circle | sed 's/circle(.*,\(.*\),.*/\1/')
            if [[ $dec_tmp =~ "[0-9]+:[0-9]+:[0-9]+" ]]; then
                dec_li=($(echo $dec_tmp | sed -e "s/:/ /g" -e"s/+//g"))
                dec=$(echo "scale=8;  ${dec_li[0]} + ${decli[1]}/60 + ${dec_li[2]}/3600" | bc)
            else
                dec=$dec_tmp
            fi

            arf_file=${xis_cam}__arf.fits
            rmf_file=${xis_cam}__rmf.fits

            rm ${arf_file} -f
            xissimarfgen instrume=${xis_cam/xi/XIS} source_mode=J2000 pointing=AUTO source_ra=$ra source_dec=$dec \
                num_region=1 region_mode=SKYREG \
                regfile1=src.reg \
                arffile1=$arf_file limit_mode=MIXED \
                num_photon=80000 accuracy=0.01 \
                phafile=$src_file detmask=$detmask_file \
                gtifile=$gti_file attitude=$att_file \
                rmffile=$rmf_file estepfile=default
        done
    done

    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuXis_4="_SuzakuXis_4_addascaspec"
alias yt_suzakuXis_addascaspec="_SuzakuXis_4_addascaspec"
function _SuzakuXis_4_addascaspec() {
    ## addascaspec
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat << EOF

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
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do

        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
        if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi
        cd $My_Suzaku_Dir/fit
        xis_cams=($(ls xi[0-3]__nongrp.fits | sed -r -n "s/^.*(xi[0-3])__.*$/\1/p"))
        xis_cams_fi=(${xis_cams[@]//xi1/})
        if [[ ${#xis_cams_fi[@]} -ge 1 ]]; then
            cat <<EOF >tmp.dat
$(echo ${xis_cams_fi[@]} | sed -r "s/(xi[0-9])\s*/\1__nongrp.fits /g")
$(echo ${xis_cams_fi[@]} | sed -r "s/(xi[0-9])\s*/\1__bkg.fits /g")
$(echo ${xis_cams_fi[@]} | sed -r "s/(xi[0-9])\s*/\1__arf.fits /g")
$(echo ${xis_cams_fi[@]} | sed -r "s/(xi[0-9])\s*/\1__rmf.fits /g")
EOF

            xis_cams_fi_sum=($(echo ${xis_cams_fi[@]} | sed -r -n "s/xi([0-9])\s*/\1/p"))
            fi_head=xis_FI$(echo ${xis_cams_fi_sum[@]} | sed -e "s/xi//g" -e "s/ //g")
            rm ${fi_head}__nongrp.fits ${fi_head}__bkg.fits ${fi_head}__rmf.fits -f
            addascaspec tmp.dat ${fi_head}__nongrp.fits ${fi_head}__rmf.fits ${fi_head}__bkg.fits
        fi

        xis_cams_bi=($(echo ${xis_cams[@]} | grep xi1 -o))
        if [[ ${#xis_cams_bi[@]} -ge 1 ]]; then
            xis_cam=${xis_cams_bi[0]}
            bi_head=xis_BI${xis_cam/xi/}
            ls ${xis_cam}__* | sed "p;s/${xis_cam}__/${bi_head}__/g" | xargs -n 2 cp
        fi
    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuXis_5="_SuzakuXis_5_editHeader"
alias yt_suzakuXis_editHeader="_SuzakuXis_5_editHeader"
function _SuzakuXis_5_editHeader() {
    ## edit header
    # args: FLAG_minimum=false
    # args: FLAG_strict=false
    # args: origSrc=nu%OBSID%A01_sr.pha
    # args: origBkg=nu%OBSID%A01_bk.pha

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--minimum] [--strict] ..." 1>&2
        cat <<EOF

${FUNCNAME[1]}
    edit header in order to compensate for losing information with addascaspec
    This function copy information from a original file header to combined one,
    and, at the same time, add the file names of bkg, rmf and arf for Xspec.


Options
--origSrc FILENAME (%OBSID% will be replaced to the observation ID)
    select the file which will be used in editting the source header information
    DEFAULT: nu%OBSID%A01_sr.pha

--origBkg FILENAME (%OBSID% will be replaced to the observation ID)
    select the file which will be used in edtting the background header information
    DEFAULT: nu%OBSID%A01_bk.pha

--minimum
    edit header with only adding the file names of bkg, rmf and arf for Xspec

--strict
    edit header with copy information wihch is the completely same values
    as all the original files and adding the file names of bkg, rmf and arf for Xspec

-h,--help
    show this message

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--help"]="help"
        ["--minimun"]="minimum"
        ["--strict"]="strict"
        ["--origSrc"]="origSrc"
        ["--origBkg"]="origBkg"
    )
    declare -A flagsArgDict=(
        ["origSrc"]="name"
        ["origBkg"]="name"
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
    origSrc=nu%OBSID%A01_sr.pha
    origBkg=nu%OBSID%A01_bk.pha

    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${flagsIn[minimum]} ]]; then
            FLAG_minimum=true
        elif [[ -n ${flagsIn[strict]} ]]; then
            FLAG_strict=true
        fi
        if [[ -n ${kwargs[origSrc__name]} ]]; then
            origSrc=${kwargs[origSrc__name]}
        fi
        if [[ -n ${kwargs[origBkg__name]} ]]; then
            origBkg=${kwargs[origBkg__name]}
        fi
    fi

    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
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

        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
        if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi
        cd $My_Suzaku_Dir/fit
        find . -type f -regextype posix-egrep -regex "\.\/xis_[A-Z]+[0-9]+__.*\..*" -printf "%f\n" |
            rename -f "s/(xis_[A-Z]+[0-9]+)__/\$1_${My_Suzaku_ID}_/"
        nongrp_names=($(find . -name "xis_*_nongrp.fits" -printf "%f\n"))
        for nongrp_name in ${nongrp_names[@]}; do
            xis_cam_fb=$(echo $nongrp_name | sed -r -n "s/^.*(xis_[A-Z]+[0-9]+)_.*$/\1/p")
            xis_fb=$(echo $xis_cam_fb | sed -r -n "s/^xis_([A-Z]+)[0-9]+$/\1/p")
            if [[ "x${xis_fb}" == "xBI" ]]; then
                nongrpExtNum=$(_ObtainExtNum $nongrp_name SPECTRUM)
                declare -A tr_keys=(
                    ["BACKFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_bkg.fits
                    ["RESPFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_rmf.fits
                    ["ANCRFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_arf.fits)

                for key in ${!tr_keys[@]}; do
                    fparkey value="${tr_keys[$key]}" \
                        fitsfile="${nongrp_name}+${nongrpExtNum}" \
                        keyword="${key}" add=yes
                done

            elif
                [[ "x${xis_fb}" == "xFI" ]]
            then

                tmp_fi_num=${xis_cam_fb/xis_FI/}
                fi_num=${tmp_fi_num:0:1}

                oldName=xi${fi_num}__nongrp.fits
                newName=${nongrp_name}
                oldExtNum=$(_ObtainExtNum $oldName SPECTRUM)
                newExtNum=$(_ObtainExtNum $newName SPECTRUM)

                cp_keys=(TELESCOP OBS_MODE DATAMODE OBS_ID OBSERVER OBJECT NOM_PNT RA_OBJ DEC_OBJ
                    RA_NOM DEC_NOM PA_NOM MEAN_EA1 MEAN_EA2 MEAN_EA3 RADECSYS EQUINOX DATE-OBS
                    DATE-END TSTART TSTOP TELAPSE ONTIME LIVETIME TIMESYS MJDREFI MJDREFF
                    TIMEREF TIMEUNIT TASSIGN CLOCKAPP TIMEDEL TIMEPIXR TIERRELA TIERABSO)

                declare -A tr_keys=(
                    ["INSTRUME"]="XIS-FI"
                    ["BACKFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_bkg.fits
                    ["RESPFILE"]=${xis_cam_fb}_${My_Suzaku_ID}_rmf.fits
                )

                for key in ${cp_keys[@]}; do
                    orig_val=$(fkeyprint infile="${oldName}+${oldExtNum}" keynam="${key}" |
                        grep "${key}\s*=" |
                        sed -r -n "s/^.*${key}\s*=\s*(.*)\s*\/.*$/\1/p")

                    tr_keys[$key]="${orig_val}"
                done

                for key in ${!tr_keys[@]}; do
                    fparkey value="${tr_keys[$key]}" \
                        fitsfile="${newName}+${newExtNum}" \
                        keyword="${key}" add=yes
                done

            fi

        done
    done

    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuXis_6="_SuzakuXis_6_grppha"
alias yt_suzakuXis_grppha="_SuzakuXis_6_grppha"
function _SuzakuXis_6_grppha() {
    ## grppha
    # args: declare -A gnums=(["FI"]=25 ["BI"]=25)

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--gnumAll GNUM_FI,BI] ..." 1>&2
        cat << EOF

${FUNCNAME[1]}
    do grouping with grppha
    In default, this function uses `group min <gnum>` for grouping
    If <gnum> for a camera is 0, then the grouping will be skipped.


Options
--gnumAll GNUM_FI,GNUM_BI
    change gnum for all cameras
    The options `--gnum<Camera>` dominate this option.

--gnumFI GNUM
--gnumBI GNUM
    change gnum for the selected camera

--gnumZero
    gnums for all cameras are set to 0

-h,--help
    show this message

EOF
        return 0
    }

    # arguments settings
    declare -A flagsAll=(
        ["h"]="help"
        ["--gnumZero"]="gnumZero"
        ["--gnumAll"]="gnumAll"
        ["--gnumFI"]="gnumFI"
        ["--gnumBI"]="gnumBI"
    )
    declare -A flagsArgDict=(
        ["gnumAll"]="gnums"
        ["gnumFI"]="gnum"
        ["gnumBI"]="gnum"
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
    declare -A gnums=(["FI"]=25 ["BI"]=25)
    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${flagsIn[gnumZero]} ]]; then
            declare -A gnums=(["FI"]=0 ["BI"]=0)
        fi
        if [[ -n ${kwargs[gnumAll__gnums]} ]]; then
            gnums_tmp=(${kwargs[gnumAll__gnums]//,/ })
            declare -A gnums=(["FI"]=${gnums_tmp[0]:-50} ["BI"]=${gnums_tmp[1]:-50})
        fi
        for cam in FI BI; do
            key_tmp=gnum${cam}__gnum
            if [[ -n ${kwargs[$key_tmp]} ]]; then
                gnums[$cam]=${kwargs[$key_tmp]}
            fi
        done
    fi

    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do

        My_Suzaku_Dir=$My_Suzaku_D/$My_Suzaku_ID/xis/event_cl
        if [[ ! -r $My_Suzaku_Dir/fit ]]; then continue; fi
        cd $My_Suzaku_Dir/fit
        nongrp_names=($(find . -name "xis_*_nongrp.fits" -printf "%f\n"))
        for nongrp_name in ${nongrp_names[@]}; do
            xis_cam_fb=$(echo $nongrp_name | sed -r -n "s/^.*(xis_[A-Z]+[0-9]+)_.*$/\1/p")
            xis_fb=$(echo $xis_cam_fb | sed -r -n "s/^xis_([A-Z]+)[0-9]+$/\1/p")
            gnum=${gnums[$xis_fb]}
            grp_name=${nongrp_name/_nongrp.fits/_grp${gnum}.fits}

            rm $grp_name -f

            cat <<EOF | bash
grppha infile=$nongrp_name \
    outfile=$grp_name
group min $gnum
exit !$grp_name
EOF
        done

    done
    cd $My_Suzaku_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_suzakuXis_7="_SuzakuXis_7_fitDirectory"
alias yt_suzakuXis_fitDirectory="_SuzakuXis_7_fitDirectory"
function _SuzakuXis_7_fitDirectory() {
    ## fitディレクトリにまとめ
    # args: FLAG_hardCopy=false
    # args: FLAG_symbLink=false
    # args: tmp_prefix="xis_"

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
    tmp_prefix="xis_"

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

    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)}
    cd $My_Suzaku_D
    mkdir -p $My_Suzaku_D/fit $My_Suzaku_D/../fit
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Suzaku_ID in ${obs_dirs[@]}; do
        if [[ ${FLAG_symbLink:=false} == "true" ]]; then
            find $My_Suzaku_D/$My_Suzaku_ID/xis/event_cl/fit/ -name "${tmp_prefix}*.*" \
                -type f -printf "%f\n" |
                xargs -n 1 -i rm -f $My_Suzaku_D/fit/{}
            ln -s $My_Suzaku_D/$My_Suzaku_ID/xis/event_cl/fit/${tmp_prefix}* ${My_Suzaku_D}/fit/
        else
            cp -f $My_Suzaku_D/$My_Suzaku_ID/xis/event_cl/fit/${tmp_prefix}* ${My_Suzaku_D}/fit/
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

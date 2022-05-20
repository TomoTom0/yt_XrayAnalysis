#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd) # noqa
source ${dir_path}/../../lib/obtain_options.sh


alias yt_nustar_1="_Nustar_1_pipeline"
alias yt_nustar_pipeline="_Nustar_1_pipeline"
function _Nustar_1_pipeline() {
    ## pipeline
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat <<EOF

${FUNCNAME[1]}
    execute first pipeline for NuSTAR FPM


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
        My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    else 
        declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    fi
    cd $My_Nustar_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Nustar_ID in ${obs_dirs[@]}; do

        My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
        if [[ ! -r $My_Nustar_Dir ]]; then continue; fi

        cd $My_Nustar_Dir

        rm -r -f $My_Nustar_Dir/out
        nupipeline indir=$My_Nustar_Dir \
            steminputs="nu$My_Nustar_ID" \
            outdir="$My_Nustar_Dir/out" saacalc="1" \
            saamode="optimized" tentacle="yes"
        # 失敗したら`rm -r $My_Nustar_Dir/out`
    done
    cd $My_Nustar_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_nustar_2="_Nustar_2_ds9"
alias yt_nustar_ds9="_Nustar_2_ds9"
function _Nustar_2_ds9() {
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
    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${flagsIn[simple]} ]]; then
            FLAG_simple=true
        fi
    fi
    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    else 
        declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Nustar_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Nustar_ID in ${obs_dirs[@]}; do

        My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
        if [[ ! -r $My_Nustar_Dir/out ]]; then continue; fi
        cd $My_Nustar_Dir/out

        evt_file=nu${My_Nustar_ID}A01_cl.evt

        if [[ ! -f ${My_Nustar_D}/saved.reg && ${FLAG_simple:=false} == false ]]; then
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
            cat <<EOF > ${My_Nustar_D}/saved.reg
# Region file format: DS9 version 4.1
global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1
fk5
circle($ra,$dec,0.026)
circle($ra_bkg,$dec_bkg,0.026) # background
EOF
        fi
        for cam in A B; do
            if [[ ${FLAG_simple:=false} == false ]]; then
                cp ${My_Nustar_D}/saved.reg fpm${cam}.reg -f
                echo ""
                echo "----  save as fpm${cam}.reg with overwriting  ----"
                echo ""
                ds9 nu${My_Nustar_ID}${cam}01_cl.evt \
                    -scale log -cmap bb -mode region \
                    -regions load fpm${cam}.reg
                ### adjust fpmA.reg / fpmB.reg
                cp fpm${cam}.reg ${My_Nustar_D}/saved.reg -f

                cat fpm${cam}.reg | grep -v -E "^circle.*# background" >src${cam}.reg
                cat fpm${cam}.reg | grep -v -E "^circle.*\)$" >bkg${cam}.reg
            else
                echo ""
                echo "----  save as fpm${cam}.reg  ----"
                echo ""
                ds9 nu${My_Nustar_ID}${cam}01_cl.evt \
                    -scale log -cmap bb -mode region
                ### make fpmA.reg / fpmB.reg
            fi
        done

    done

    cd $My_Nustar_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_nustar_3="_Nustar_3_products"
alias yt_nustar_products="_Nustar_3_products"
function _Nustar_3_products() {
    ## nuproducts
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat <<EOF

${FUNCNAME[1]}
    many files will be generated with nuproductus


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
        My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    else 
        declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Nustar_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Nustar_ID in ${obs_dirs[@]}; do

        My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
        if [[ ! -r $My_Nustar_Dir ]]; then continue; fi

        cd $My_Nustar_Dir

        rm $My_Nustar_Dir/fit/* -rf &&
            mkdir $My_Nustar_Dir/fit -p
        for cam in A B; do
            nuproducts \
                srcregionfile=$My_Nustar_Dir/out/src${cam}.reg \
                bkgregionfile=$My_Nustar_Dir/out/bkg${cam}.reg \
                indir=$My_Nustar_Dir/out \
                outdir=$My_Nustar_Dir/fit \
                instrument=FPM${cam} \
                steminputs=nu${My_Nustar_ID} \
                bkgextract=yes \
                clobber=yes
        done

    done
    cd $My_Nustar_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_nustar_4="_Nustar_4_addascaspec"
alias yt_nustar_addascaspec="_Nustar_4_addascaspec"
function _Nustar_4_addascaspec() {
    ## addascaspec
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat <<EOF

${FUNCNAME[1]}
    combine files FPMA and FPMB with addascaspec


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
        My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    else 
        declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Nustar_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Nustar_ID in ${obs_dirs[@]}; do

        My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
        if [[ ! -r $My_Nustar_Dir/fit ]]; then continue; fi

        cd $My_Nustar_Dir/fit

        cat <<EOF >tmp_fi.add
nu${My_Nustar_ID}A01_sr.pha nu${My_Nustar_ID}B01_sr.pha
nu${My_Nustar_ID}A01_bk.pha nu${My_Nustar_ID}B01_bk.pha
nu${My_Nustar_ID}A01_sr.arf nu${My_Nustar_ID}B01_sr.arf
nu${My_Nustar_ID}A01_sr.rmf nu${My_Nustar_ID}B01_sr.rmf
EOF

        rm AB_${My_Nustar_ID}_nongrp.fits \
            AB_${My_Nustar_ID}_rsp.fits \
            AB_${My_Nustar_ID}_bkg.fits -f
        addascaspec tmp_fi.add \
            AB_${My_Nustar_ID}_nongrp.fits \
            AB_${My_Nustar_ID}_rsp.fits \
            AB_${My_Nustar_ID}_bkg.fits
    done
    cd $My_Nustar_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_nustar_5="_Nustar_5_editHeader"
alias yt_nustar_editHeader="_Nustar_5_editHeader"
function _Nustar_5_editHeader() {
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
    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    else 
        declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Nustar_D
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
    for My_Nustar_ID in ${obs_dirs[@]}; do

        My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
        if [[ ! -r $My_Nustar_Dir/fit ]]; then continue; fi

        cd $My_Nustar_Dir/fit
        nongrp_name=AB_${My_Nustar_ID}_nongrp.fits

        ### edit header for spectrum file
        _oldName_tmp=${origSrc/\%OBSID%/${My_Nustar_ID}}
        if [[ -r ${_oldName_tmp} ]]; then
            oldName=${_oldName_tmp}
        else
            oldName=nu${My_Nustar_ID}A01_sr.pha
        fi
        newName=$nongrp_name
        oldExtNum=$(_ObtainExtNum $oldName SPECTRUM)
        newExtNum=$(_ObtainExtNum $newName SPECTRUM)

        #### same values
        cp_keys=(TELESCOP OBS_ID TARG_ID OBJECT RA_OBJ
            DEC_OBJ RA_NOM DEC_NOM RA_PNT DEC_PNT PA_PNT
            EQUINOX RADECSYS TASSIGN TIMESYS MJDREFI MJDREFF
            TIMEREF CLOCKAPP TIMEUNIT TSTOP DATE-OBS DATE-END
            ORIGIN DATETLM TLM2FITS SOFTVER CALDBVER USER
            TIMEZERO DEADAPP TSORTKEY NUFLAG ABERRAT FOLOWSUN
            DSTYP1 DSVAL1 NUPSDOUT DEPTHCUT OBSMODE HDUNAME
            AXLEN1 AXLEN2 CONTENT WMREBIN OBS-MODE SKYBIN
            PIXSIZE WMAPFIX DSTYP2 DSREF2 DSVAL2 CTYPE1 DRPIX1
            CRVAL1 CDELT1 DDELT1 CTYPE2 DRPIX2 CRVAL2 CDELT2
            DDELT2 WCSNAMEP WCSTY1P LTM1_1 CTYPE1P CRPIX1P
            CDELT1P WCSTY2P LTM2_2 CTYPE2P CRPIX2P CDELT2P
            OPTIC1 OPTIC2 HBBOX1 HBBOX2 REFXCTYP REFXCRPX
            REFXCRVL REFXCDLT REFYCTYP REFYCRPX REFYCRVL REFYCDLT)

        #### near values
        cp_keys2=(INSTRUME TSTART TELAPSE ONTIME LIVETIME
            MJD-OBS FILIN001 DEADC NPIXSOU CRPIX1 CRPIX2 LTV1
            CRVAL1P LTV2 CRVAL2P BBOX1 BBOX2 X-OFFSET
            Y-OFFSET TOTCTS)

        if [[ ${FLAG_strict:=false} == "true" ]]; then
            cp_keys2=()
        fi
        if [[ ${FLAG_minimum:=false} == "true" ]]; then
            cp_keys=()
            cp_keys2=()
        fi

        declare -A tr_keys=(
            ["BACKFILE"]="AB_${My_Nustar_ID}_bkg.fits"
            ["RESPFILE"]="AB_${My_Nustar_ID}_rsp.fits"
        )

        for key in ${cp_keys[@]} ${cp_keys2[@]}; do
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

        ### edit header for bkg file
        _oldName_tmp=${origBkg/\%OBSID%/${My_Nustar_ID}}
        if [[ -r ${_oldName_tmp} ]]; then
            oldName=${_oldName_tmp}
        else
            oldName=nu${My_Nustar_ID}A01_bk.pha
        fi
        newName=AB_${My_Nustar_ID}_bkg.fits
        oldExtNum=$(_ObtainExtNum $oldName SPECTRUM)
        newExtNum=$(_ObtainExtNum $newName SPECTRUM)

        #### same values
        cp_keys=(TELESCOP OBS_ID TARG_ID OBJECT RA_OBJ
            DEC_OBJ RA_NOM DEC_NOM RA_PNT DEC_PNT PA_PNT
            EQUINOX RADECSYS TASSIGN TIMESYS MJDREFI MJDREFF
            TIMEREF CLOCKAPP TIMEUNIT TSTART TSTOP TELAPSE
            DATE-OBS DATE-END ORIGIN CREATOR DATETLM TLM2FITS
            SOFTVER CALDBVER MJD-OBS USER FILIN001 TIMEZERO
            DEADAPP TSORTKEY NUFLAG ABERRAT FOLOWSUN DSTYP1
            DSVAL1 NPIXSOU NUPSDOUT DEPTHCUT OBSMODE HDUNAME
            AXLEN1 AXLEN2 CONTENT WMREBIN OBS-MODE SKYBIN
            PIXSIZE WMAPFIX DSTYP2 DSREF2 DSVAL2 CTYPE1 CRPIX1
            DRPIX1 CRVAL1 CDELT1 DDELT1 CTYPE2 CRPIX2 DRPIX2
            CRVAL2 CDELT2 DDELT2 WCSNAMEP WCSTY1P LTV1 LTM1_1
            CTYPE1P CRPIX1P CRVAL1P CDELT1P WCSTY2P LTV2
            LTM2_2 CTYPE2P CRPIX2P CRVAL2P CDELT2P OPTIC1
            OPTIC2 BBOX1 BBOX2 HBBOX1 HBBOX2 X-OFFSET Y-OFFSET
            REFXCTYP REFXCRPX REFXCRVL REFXCDLT REFYCTYP
            REFYCRPX REFYCRVL REFYCDLT)

        #### near values
        cp_keys2=(INSTRUME DATE ONTIME LIVETIME DEADC)

        if [[ ${FLAG_strict:=false} == "true" ]]; then
            cp_keys2=()
        fi
        if [[ ${FLAG_minimum:=false} == "true" ]]; then
            cp_keys=()
            cp_keys2=()
        fi

        declare -A tr_keys=()

        for key in ${cp_keys[@]} ${cp_keys2[@]}; do
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
    done
    cd $My_Nustar_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_nustar_6="_Nustar_6_grppha"
alias yt_nustar_grppha="_Nustar_6_grppha"
function _Nustar_6_grppha() {
    ## grppha
    # args: gnum=50

    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--gnum GNUM] ..." 1>&2
        cat <<EOF

${FUNCNAME[1]}
    do grouping with grppha
    In default, this function uses "group min GNUM" for grouping
    If gnum for a camera is 0, then the grouping will be skipped.


Options
--gnum GNUM
    change gnum for EMOS1+EMOS2


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
    declare -A gnum=50
    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${kwargs[gnum__gnum]} ]]; then
            declare -i gnum=${kwargs[gnum__gnum]}
        fi
    fi
    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    else 
        declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Nustar_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Nustar_ID in ${obs_dirs[@]}; do

        My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
        if [[ ! -r $My_Nustar_Dir/fit ]]; then continue; fi
        cd $My_Nustar_Dir/fit/
        if [[ ${gnum} -le 0 ]]; then continue; fi
        grp_name=AB_${My_Nustar_ID}_grp${gnum}.fits
        rm ${grp_name} -f
        cat <<EOF | bash
grppha infile=AB_${My_Nustar_ID}_nongrp.fits outfile=${grp_name} clobber=true
group min ${gnum}
exit !${grp_name}
EOF
    done
    cd $My_Nustar_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_nustar_7="_Nustar_7_fitDirectory"
alias yt_nustar_fitDirectory="_Nustar_7_fitDirectory"
function _Nustar_7_fitDirectory() {
    ## fitディレクトリにまとめ
    # args: FLAG_hardCopy=false
    # args: FLAG_symbLink=false
    # args: tmp_prefix="AB_"

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
    tmp_prefix="AB_"

    if [[ x${FUNCNAME} != x ]]; then
        if [[ -n ${flagsIn[hardCopy]} ]]; then
            FLAG_hardCopy=true
        fi
        if [[ -n ${flagsIn[symbLink]} ]]; then
            FLAG_symbLink=true
        fi
        if [[ -n ${kwargs[prefixName__name]} ]]; then
            tmp_prefix=${kwargs[prefixName__name]}
        fi
    fi
    if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
        My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    else 
        declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Nustar_D

    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    mkdir -p $My_Nustar_D/fit $My_Nustar_D/../fit/
    for My_Nustar_ID in ${obs_dirs[@]}; do
        cp $My_Nustar_D/$My_Nustar_ID/fit/${tmp_prefix}* $My_Nustar_D/fit/ -f
    done
    ### remove the files with the same name as new files
    find $My_Nustar_D/fit/ -name "${tmp_prefix}*.*" \
        -type f -printf "%f\n" |
        xargs -n 1 -i rm -f $My_Nustar_D/../fit/{}
    ### remove broken symbolic links
    find -L $My_Nustar_D/../fit/ -type l -delete
    ### generate symbolic links
    ln -s $My_Nustar_D/fit/${tmp_prefix}*.* $My_Nustar_D/../fit/
    cd $My_Nustar_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

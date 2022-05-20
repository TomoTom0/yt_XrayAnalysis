#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd) # noqa
source ${dir_path}/../../lib/obtain_options.sh


alias yt_swiftXrt_1="_SwiftXrt_1_pipeline"
alias yt_swiftXrt_pipeline="_SwiftXrt_1_pipeline"
function _SwiftXrt_1_pipeline() {
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
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi
    cd $My_Swift_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Swift_ID in ${obs_dirs[@]}; do

        My_Swift_Dir=$My_Swift_D/$My_Swift_ID
        if [[ ! -r $My_Swift_Dir ]]; then continue; fi

        cd $My_Swift_Dir
        rm $My_Swift_Dir/xrt/output -rf
        mkdir $My_Swift_Dir/xrt/output -p
        xrtpipeline indir=$My_Swift_Dir \
            outdir="$My_Swift_Dir//xrt/output" \
            steminputs=sw${My_Swift_ID} \
            srcra=OBJECT srcdec=OBJECT clobber=yes
    done
    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrt_2="_SwiftXrt_2_ds9"
alias yt_swiftXrt_ds9="_SwiftXrt_2_ds9"
function _SwiftXrt_2_ds9() {
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
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Swift_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Swift_ID in ${obs_dirs[@]}; do

        My_Swift_Dir=$My_Swift_D/$My_Swift_ID
        if [[ ! -r $My_Swift_Dir/xrt/output ]]; then continue; fi
        cd $My_Swift_Dir/xrt/output
        _evt_tmps=($(find . -name sw${My_Swift_ID}xpcw*po_cl.evt))
        evt_file=${_evt_tmps[-1]}

        if [[ ! -f ${My_Swift_D}/saved.reg && ${FLAG_simple:=false} == false ]]; then
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
            cat <<EOF > ${My_Swift_D}/saved.reg
# Region file format: DS9 version 4.1
global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1
fk5
circle($ra,$dec,0.026)
circle($ra_bkg,$dec_bkg,0.026) # background
EOF
        fi
        reg_file=xrt.reg
        if [[ ! -f "${evt_file}"  ]]; then
            echo ""
            echo "----   event_file not found"
            echo ""
            continue
        elif [[ ${FLAG_simple:=false} == false  ]]; then
            cp ${My_Swift_D}/saved.reg $reg_file -f
            echo ""
            echo "----  opening $evt_file"
            echo "----  save as $reg_file with overwriting"
            echo ""
            ds9 $evt_file \
                -scale log -cmap bb -mode region \
                -regions load $reg_file
            ### adjust xrt.reg

            cp $reg_file ${My_Swift_D}/saved.reg -f

            cat ${reg_file} | grep -v -E "^circle.*# background" >src.reg
            cat ${reg_file} | grep -v -E "^circle.*\)$" >bkg.reg
        else
            echo ""
            echo "----  opening $evt_file"
            echo "----  save as $reg_file"
            echo ""
            ds9 $evt_file \
                -scale log -cmap bb -mode region
        fi
    done

    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrt_3="_SwiftXrt_3_products"
alias yt_swiftXrt_products="_SwiftXrt_3_products"
function _SwiftXrt_3_products() {
    ## xrtproducts
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
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Swift_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Swift_ID in ${obs_dirs[@]}; do

        My_Swift_Dir=$My_Swift_D/$My_Swift_ID
        if [[ ! -r $My_Swift_Dir/xrt/output ]]; then continue; fi

        cd $My_Swift_Dir/xrt/output
        _evt_tmps=($(find . -name "sw${My_Swift_ID}xpcw*po_cl.evt" -printf "%f\n"))
        evt_file=${_evt_tmps[-1]}

        _exp_tmps=($(find . -name "sw${My_Swift_ID}xpcw*po_ex.img" -printf "%f\n"))
        exp_file=${_exp_tmps[0]}

        if [[ ! -f "$evt_file" || ! -f "$evt_file" ]]; then continue; fi

        # unable to open xrt__nongrp.fitsで動かない……とりあえずxselectで代用
        #rm $My_Swift_Dir/xrt/output/fit/* -rf
        #xrtproducts infile=$evt_file stemout=DEFAULT regionfile=src.reg \
        #    bkgregionfile=bkg.reg bkgextract=yes outdir="$My_Swift_Dir/xrt/output/fit" binsize=-99 \
        #    expofile=$exp_file clobber=yes correctlc=no \
        #    phafile=xrt__nongrp.fits bkgphafile=xrt__bkg.fits arffile=xrt__arf.fits

        cat <<EOF | bash
xselect
xsel
read events $evt_file
./
y
extract all
filter region src.reg
extract spectrum
save spectrum xrt__nongrp.fits
clear region
filter region bkg.reg
extract spectrum
save spectrum xrt__bkg.fits
exit
n

EOF

        cat << EOF | bash
xrtmkarf phafile=xrt__nongrp.fits srcx=-1 srcy=-1 outfile=xrt__arf.fits extended=no expofile=${exp_file}
yes
EOF
        mkdir fit -p
        mv xrt__nongrp.fits xrt__bkg.fits xrt__arf.fits fit/

    done
    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrt_4="_SwiftXrt_4_obtainRmf"
alias yt_swiftXrt_obtainRmf="_SwiftXrt_4_obtainRmf"
function _SwiftXrt_4_obtainRmf() {
    ## obtain rmf
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--rmf] [--arf]" 1>&2
        cat << EOF

${FUNCNAME[1]}
    make symbolic link of rmf file from CALDB


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
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrt_5="_SwiftXrt_5_editHeader"
alias yt_swiftXrt_editHeader="_SwiftXrt_5_editHeader"
function _SwiftXrt_5_editHeader() {
    ## edit header
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] [--minimum] [--strict] ..." 1>&2
        cat <<EOF

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
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Swift_D
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
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Swift_ID in ${obs_dirs[@]}; do

        My_Swift_Dir=$My_Swift_D/$My_Swift_ID
        if [[ ! -r $My_Swift_Dir/xrt/output/fit ]]; then continue; fi

        cd $My_Swift_Dir/xrt/output/fit

        find . -name "xrt__*" |
            rename -f "s/xrt__/xrt_${My_Swift_ID}_/"

        nongrp_name=xrt_${My_Swift_ID}_nongrp.fits
        nongrpExtNum=$(_ObtainExtNum $nongrp_name SPECTRUM)

        declare -A tr_keys=(
            ["BACKFILE"]=xrt_${My_Swift_ID}_bkg.fits
            ["RESPFILE"]=xrt_${My_Swift_ID}_rmf.fits
            ["ANCRFILE"]=xrt_${My_Swift_ID}_arf.fits)

        for key in ${!tr_keys[@]}; do
            fparkey value="${tr_keys[$key]}" \
                fitsfile="${nongrp_name}+${nongrpExtNum}" \
                keyword="${key}" add=yes
        done

    done

    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrt_6="_SwiftXrt_6_grppha"
alias yt_swiftXrt_grppha="_SwiftXrt_6_grppha"
function _SwiftXrt_6_grppha() {
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
    If gnum for a camera is less than or equal to 0, then the grouping will be skipped.


Options
--gnum GNUM
    change gnum for Swift XRT

-h,--help
    show this message

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
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Swift_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Swift_ID in ${obs_dirs[@]}; do

        My_Swift_Dir=$My_Swift_D/$My_Swift_ID
        if [[ ! -r $My_Swift_Dir/xrt/output/fit/ ]]; then continue; fi

        cd $My_Swift_Dir/xrt/output/fit/
        nongrp_name=xrt_${My_Swift_ID}_nongrp.fits
        grp_name=xrt_${My_Swift_ID}_grp${gnum}.fits
        rm $grp_name -f
        cat <<EOF | bash
grppha infile=$nongrp_name outfile=$grp_name
group min ${gnum}
exit !$grp_name
EOF

    done
    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrt_7="_SwiftXrt_7_fitDirectory"
alias yt_swiftXrt_fitDirectory="_SwiftXrt_7_fitDirectory"
function _SwiftXrt_7_fitDirectory() {
    ## fitディレクトリにまとめ
    # args: FLAG_hardCopy=false
    # args: FLAG_symbLink=false
    # args: tmp_prefix="xrt_"

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
    tmp_prefix="xrt_"
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
        My_Swift_D=${My_Swift_D:=$(pwd)} 
    else 
        declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
    fi # 未定義時に代入
    cd $My_Swift_D
    mkdir -p $My_Swift_D/fit $My_Swift_D/../fit
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Swift_ID in ${obs_dirs[@]}; do
        if [[ ${FLAG_symbLink:=false} == "true" ]]; then
            find $My_Swift_D/$My_Swift_ID/xrt/output/fit/ -name "${tmp_prefix}*.*" \
                -type f -printf "%f\n" |
                xargs -n 1 -i rm -f $My_Swift_D/fit/{}
            ln -s $My_Swift_D/$My_Swift_ID/xrt/output/fit/${tmp_prefix}* ${My_Swift_D}/fit/
        else
            if [[ ! -d "$My_Swift_D/$My_Swift_ID/xrt/output/fit/" ]]; then continue; fi
            find $My_Swift_D/$My_Swift_ID/xrt/output/fit/ -name "${tmp_prefix}*" | xargs -i cp {} ${My_Swift_D}/fit/
            #cp -f $My_Swift_D/$My_Swift_ID/xrt/output/fit/${tmp_prefix}* ${My_Swift_D}/fit/
        fi
    done
    if [[ ${FLAG_hardCopy:=false} == "true" ]]; then
        cp -f $My_Swift_D/fit/${tmp_prefix}*.* $My_Swift_D/../fit/
    else
            # remove the files with the same name as new files
        find $My_Swift_D/fit/ -name "${tmp_prefix}*.*" \
            -type f -printf "%f\n" |
            xargs -n 1 -i rm -f $My_Swift_D/../fit/{}
        # generate symbolic links
        ln -s $My_Swift_D/fit/${tmp_prefix}*.* $My_Swift_D/../fit/
    fi
    # remove broken symbolic links
    find -L $My_Swift_D/../fit/ -type l -delete
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

#!/bin/bash

dir_path=$(
    cd $(dirname ${BASH_SOURCE:-$0})
    pwd
) # noqa
source ${dir_path}/../../lib/obtain_options.sh

alias yt_swiftUvot_1="_SwiftUvot_1_ds9"
alias yt_swiftUvot_ds9="_SwiftUvot_1_ds9"
function _SwiftUvot_1_ds9() {
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
        if [[ ! -r $My_Swift_Dir/uvot/image ]]; then continue; fi
        cd $My_Swift_Dir/uvot/image
        img_files=($(find . -name "sw${My_Swift_ID}*_sk.img.gz" -printf "%f\n" ))
        evt_file=${img_files[-1]}

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
            cat <<EOF >${My_Swift_D}/saved.reg
# Region file format: DS9 version 4.1
global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1
fk5
circle($ra,$dec,0.026)
circle($ra_bkg,$dec_bkg,0.026) # background
EOF
        fi
        for img_file in ${img_files[@]}; do
            band=$(echo $img_file | sed -r -n "s/^.*sw${My_Swift_ID}([a-z0-9]+)_sk.img.gz$/\1/p")
            reg_file=${band}.reg
            if [[ ! -f "${evt_file}" ]]; then
                echo ""
                echo "----   event_file not found"
                echo ""
                continue
            elif [[ ${FLAG_simple:=false} == false ]]; then
                cp ${My_Swift_D}/saved.reg $reg_file -f
                echo ""
                echo "----  opening $img_file"
                echo "----  save as $reg_file with overwriting"
                echo ""
                ds9 $img_file \
                    -scale log -cmap bb -mode region \
                    -regions load $reg_file
                ### adjust xrt.reg

                
                tmp_reg="tmp.reg"
                ds9 $img_file -regions load $reg_file -regions system fk5 \
                    -regions centroid -regions save $tmp_reg -exit &&
                cp $tmp_reg ${My_Swift_D}/saved.reg -f

                cat $tmp_reg | grep -v -E "^circle.*# background" > src_${band}.reg
                cat $tmp_reg | grep -v -E "^circle.*\)$" > bkg_${band}.reg
            else
                echo ""
                echo "----  opening $evt_file"
                echo "----  save as $reg_file"
                echo ""
                ds9 $img_file \
                    -scale log -cmap bb -mode region
            fi
        done
    done

    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftUvot_2="_SwiftUvot_2_products"
alias yt_swiftUvot_products="_SwiftUvot_2_products"
function _SwiftUvot_2_products() {
    ## products
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
        if [[ ! -r $My_Swift_Dir/uvot/image ]]; then continue; fi

        cd $My_Swift_Dir/uvot/image
        mkdir $My_Swift_Dir/uvot/image/fit -p
        img_files=($(find . -name "sw${My_Swift_ID}*_sk.img*" -printf "%f\n"))
        for img_file in ${img_files[@]}; do
            band=$(echo $img_file | sed -e "s/sw${My_Swift_ID}\(.*\)_sk.img.gz/\1/g")

            if [[ "x$band" == "x" ]]; then continue; fi

            # rspのシンボリックリンク作成
            ## uvotにarfは不要
            _rsp_tmps=($(find "${CALDB}/data/swift/uvota/cpf/rsp/" -name "sw${band}_*.rsp" | sort -r))
            rsp_file=${_rsp_tmps[-1]}
            rm fit/tmp_uvot__${band}_rsp.fits -f &&
                ln -s "$rsp_file" fit/tmp_uvot__${band}_rsp.fits

            #rm tmp_${band}.fits -f
            ## uvotimsumは不要?? 公式でもmanualと手順の場所でばらついてる
            #uvotimsum infile=${img_file} outfile=tmp_${band}.fits chatter=1
            if [[ ! -f "src_${band}.reg" ]]; then
                echo $My_Swift_ID $band
            continue; fi
            rm fit/tmp_uvot__${band}_src.fits \
                fit/tmp_uvot__${band}_bkg.fits -f
            uvot2pha infile=${img_file}+1 srcreg=src_${band}.reg \
                bkgreg=bkg_${band}.reg \
                srcpha=fit/tmp_uvot__${band}_src.fits \
                bkgpha=fit/tmp_uvot__${band}_bkg.fits \
                respfile=fit/tmp_uvot__${band}_rsp.fits \
                clobber=y chatter=1

        done

    done
    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftUvot_3="_SwiftUvot_3_addascaspec"
alias yt_swiftUvot_addascaspec="_SwiftUvot_3_addascaspec"
function _SwiftUvot_3_addascaspec() {
    ## obtain rmf
    # ---------------------
    ##     obtain options
    # ---------------------

    function __usage() {
        echo "Usage: ${FUNCNAME[1]} [-h,--help] " 1>&2
        cat <<EOF

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

    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Swift_ID in ${obs_dirs[@]}; do

        My_Swift_Dir=$My_Swift_D/$My_Swift_ID
        if [[ ! -r $My_Swift_Dir/uvot/image/fit ]]; then continue; fi

        cd $My_Swift_Dir/uvot/image/fit

        find . -name "tmp_uvot__*.fits" |
            rename "s/tmp_uvot__/tmp_uvot_${My_Swift_ID}_/" -f

        uvot_band_all=($(find . -name "tmp_uvot_${My_Swift_ID}_*_src.fits" -printf "%f\n" |
            sed -r "s/^tmp_uvot_${My_Swift_ID}_([a-z0-9]+)_.*$/\1/"))
        uvot_band_sum=$(echo ${uvot_band_all[@]} | sed "s/ /_/g")
        new_uvot_names=($(echo -n "src rsp bkg" | xargs -n 1 -d" " \
            -i echo uvot_${My_Swift_ID}_${uvot_band_sum}_{}.fits))
        rm uvot_*.fits -f
        if [[ ! 1 && ${#uvot_band_all[@]} -ge 2 ]]; then

            cat <<EOF >tmp_fi.add
$(find . -name "tmp_uvot_${My_Swift_ID}_*_src.fits" -printf "%P ")
$(find . -name "tmp_uvot_${My_Swift_ID}_*_bkg.fits" -printf "%P ")
$(find . -name "tmp_uvot_${My_Swift_ID}_*_rsp.fits" -printf "%P ")
EOF

            rm ${new_uvot_names[@]} -f
            addascaspec tmp_fi.add ${new_uvot_names[@]}
        fi

        if [[ ${#uvot_band_all[@]} -ge 1 ]]; then
            for band in ${uvot_band_all[@]}; do
                #band=${uvot_band_sum}
                echo -n "bkg rsp" | xargs -n 1 -i -d" " cp tmp_uvot_${My_Swift_ID}_${band}_{}.fits uvot_${My_Swift_ID}_${band}_{}.fits -f
                cat <<EOF | bash
grppha infile=tmp_uvot_${My_Swift_ID}_${band}_src.fits outfile=uvot_${My_Swift_ID}_${band}_src.fits clobber=true
chkey BACKFILE uvot_${My_Swift_ID}_${band}_bkg.fits
chkey RESPFILE uvot_${My_Swift_ID}_${band}_rsp.fits+1
exit
EOF
            done
        fi
    done

    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftUvot_4="_SwiftUvot_4_fitDirectory"
alias yt_swiftUvot_fitDirectory="_SwiftUvot_4_fitDirectory"
function _SwiftUvot_4_fitDirectory() {
    ## fitディレクトリにまとめ
    # args: FLAG_hardCopy=false
    # args: FLAG_symbLink=false
    # args: tmp_prefix="uvot_"

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
    tmp_prefix="uvot_"
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
            find $My_Swift_D/$My_Swift_ID/uvot/image/fit/ -name "${tmp_prefix}*.*" \
                -type f -printf "%f\n" |
                xargs -n 1 -i rm -f $My_Swift_D/fit/{}
            ln -s $My_Swift_D/$My_Swift_ID/uvot/image/fit/${tmp_prefix}* ${My_Swift_D}/fit/
        else
            if [[ ! -d "$My_Swift_D/$My_Swift_ID/uvot/image/fit/" ]]; then continue; fi
            find $My_Swift_D/$My_Swift_ID/uvot/image/fit/ -name "${tmp_prefix}*" | xargs -i cp {} ${My_Swift_D}/fit/
            #cp -f $My_Swift_D/$My_Swift_ID/uvot/image/fit/${tmp_prefix}* ${My_Swift_D}/fit/
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

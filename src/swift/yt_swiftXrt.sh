#!/bin/bash

alias yt_swiftXrt_1="_SwiftXrt_1_pipeline"
alias yt_swiftXrt_pipeline="_SwiftXrt_1_pipeline"
function _SwiftXrt_1_pipeline() {
    ## pipeline
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)}
    cd $My_Swift_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Swift_ID in ${obs_dirs[@]}; do

        My_Swift_Dir=$My_Swift_D/$My_Swift_ID
        if [[ ! -r $My_Swift_Dir ]]; then continue; fi

        cd $My_Swift_Dir
        rm $My_Swift_Dir/xrt/output -rf
        mkdir $My_Swift_Dir/xrt/output -p
        xrtpipeline indir=$My_Swift_Dir \
            outdir="$My_Swift_Dir/xrt/output" \
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
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} # 未定義時に代入
    cd $My_Swift_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Swift_ID in ${obs_dirs[@]}; do

        My_Swift_Dir=$My_Swift_D/$My_Swift_ID
        if [[ ! -r $My_Swift_Dir/xrt/out ]]; then continue; fi
        cd $My_Swift_Dir/xrt/output
        evt_tmps=($(ls -r sw${My_Swift_ID}xpcw*po_cl.evt))
        evt_file=${evt_tmps[0]}

        if [[ ! -f ${My_Swift_D}/saved.reg ]]; then
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
                -regions save $My_Swift_D/saved.reg -exit
        fi
        reg_file=xrt.reg
        cp ${My_Swift_D}/saved.reg $reg_file -f
        echo "----  save as $reg_file with overwriting  ----"
        ds9 $evt_file \
            -scale log -cmap bb -mode region \
            -regions load $reg_file
        ### adjust xrt.reg

        cp $reg_file ${My_Swift_D}/saved.reg -f

        cat ${reg_file} | grep -v -E "^circle.*# background" >src.reg
        cat ${reg_file} | grep -v -E "^circle.*\)$" >bkg.reg
    done

    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrt_3="_SwiftXrt_3_products"
alias yt_swiftXrt_products="_SwiftXrt_3_products"
function _SwiftXrt_3_products() {
    ## xrtproducts
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} # 未定義時に代入
    cd $My_Swift_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Swift_ID in ${obs_dirs[@]}; do

        My_Swift_Dir=$My_Swift_D/$My_Swift_ID
        if [[ ! -r $My_Swift_Dir/xrt/output ]]; then continue; fi

        cd $My_Swift_Dir/xrt/output
        _evt_tmps=($(ls -r sw${My_Swift_ID}xpcw*po_cl.evt))
        evt_file=${_evt_tmps[-1]}

        _exp_tmps=($(ls -r sw${My_Swift_ID}xpcw*po_ex.img))
        exp_file=${_exp_tmps[0]}
        xrtproducts infile=$evt_file stemout=DEFAULT regionfile=src.reg \
            bkgregionfile=bkg.reg bkgextract=yes outdir=$My_Swift_Dir/xrt/output/fit binsize=-99 \
            expofile=$exp_file clobber=yes correctlc=no \
            phafile=xrt__nongrp.fits bkgphafile=xrt__bkg.fits arffile=xrt__arf.fits

    done
    cd $My_Swift_D
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

alias yt_swiftXrt_4="_SwiftXrt_4_obtainRmf"
alias yt_swiftXrt_obtainRmf="_SwiftXrt_4_obtainRmf"
function _SwiftXrt_4_obtainRmf() {
    ## obtain rmf
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} # 未定義時に代入
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

    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
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

        if [[ "x$rmf_version" == "xNone" ]]; then
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
function _SwiftXrt_5_editHEader() {
    ## edit header
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} # 未定義時に代入
    cd $My_Swift_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    for My_Swift_ID in ${obs_dirs[@]}; do

        My_Swift_Dir=$My_Swift_D/$My_Swift_ID
        if [[ ! -r $My_Swift_Dir/xrt/output/fit ]]; then continue; fi

        cd $My_Swift_Dir/xrt/output/fit

        find . -name "xrt__*" |
            rename -f "s/xrt__/xrt_${My_Swift_ID}_/"

        nongrp_name=xrt_${My_Swift_ID}_nongrp.fits

        declare -A tr_keys=(
            ["BACKFILE"]=xrt_${My_Swift_ID}_bkg.fits
            ["RESPFILE"]=xrt_${My_Swift_ID}_rmf.fits
            ["ANCRFILE"]=xrt_${My_Swift_ID}_arf.fits)

        for key in ${!tr_keys[@]}; do
            fparkey value="${tr_keys[$key]}" \
                fitsfile=${nongrp_name}+1 \
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
    if [[ x${FUNCNAME} != x ]]; then
        _gnum_tmp=${1:=50}
        if [[ $_gnum_tmp =~ [0-9]+ ]]; then
            gnum=$_gnum_tmp
        else
            gnum=50
        fi
    else
        gnum=50
    fi
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} # 未定義時に代入
    cd $My_Swift_D
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
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
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} # 未定義時に代入
    cd $My_Swift_D
    tmp_prefix="xrt_"
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
    mkdir -p $My_Swift_D/fit $My_Swift_D/../fit/
    for My_Swift_ID in ${obs_dirs[@]}; do
        cp $My_Swift_D/$My_Swift_ID/xrt/output/fit/${tmp_prefix}* $My_Swift_D/fit/ -f
    done
    ### remove the files with the same name as new files
    find $My_Swift_D/fit/ -name "${tmp_prefix}*.*" \
        -type f -printf "%f\n" |
        xargs -n 1 -i rm -f $My_Swift_D/../fit/{}
    ### remove broken symbolic links
    find -L $My_Swift_D/../fit/ -type l -delete
    ### generate symbolic links
    ln -s $My_Swift_D/fit/${tmp_prefix}*.* $My_Swift_D/../fit/
    if [[ x${FUNCNAME} != x ]]; then return 0; fi
}

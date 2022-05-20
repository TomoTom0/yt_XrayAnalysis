# _SuzakuXis_b_afterDs9
# _SuzakuXis_2_xselect
## extarct spec with xselect
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
fi
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
# _SuzakuXis_3_genRmfArf
## rmfおよびarf作成
FLAG_rmf=true # arg
FLAG_arf=true # arg
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
fi
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
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
else 
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
fi
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
# _SuzakuXis_4_addascaspec
## addascaspec
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
fi
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
# _SuzakuXis_5_editHeader
## edit header
FLAG_minimum=false # arg
FLAG_strict=false # arg
origSrc=nu%OBSID%A01_sr.pha # arg
origBkg=nu%OBSID%A01_bk.pha # arg
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
# _SuzakuXis_6_grppha
## grppha
declare -A gnums=(["FI"]=25 ["BI"]=25) # arg
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
fi
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
# _SuzakuXis_7_fitDirectory
## fitディレクトリにまとめ
FLAG_hardCopy=false # arg
FLAG_symbLink=false # arg
tmp_prefix="xis_" # arg
    declare -g My_Suzaku_D=${My_Suzaku_D:=$(pwd)} 
fi
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
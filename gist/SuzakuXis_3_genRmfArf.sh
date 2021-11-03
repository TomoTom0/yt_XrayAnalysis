# _SuzakuXis_3_genRmfArf
## rmfおよびarf作成
echo ${My_Suzaku_D:=$(pwd)}
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
        rm ${xis_cam}__src.rmf -f
        xisrmfgen phafile=$src_file outfile=${xis_cam}__src.rmf
    done
done
cd $My_Suzaku_D

### arf
echo ${My_Suzaku_D:=$(pwd)}
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

        arf_file=${xis_cam}__src.arf
        rmf_file=${xis_cam}__src.rmf

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
# _NicerXti_2_obtainBkg
## obtain bkg
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then
    My_Nicer_D=${My_Nicer_D:=$(pwd)}
else
    declare -g My_Nicer_D=${My_Nicer_D:=$(pwd)}
fi # 未定義時に代入
cd $My_Nicer_D

# nibackestimator
if [[ -x $(which nibkgestimator) ]]; then
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Nicer_ID in ${obs_dirs[@]}; do

        My_Nicer_Dir=$My_Nicer_D/$My_Nicer_ID
        if [[ ! -r $My_Nicer_Dir/xti/event_cl/fit ]]; then continue; fi

        cd $My_Nicer_Dir/xti/event_cl/fit

        # toolの兼ね合いで名前を.phaに変更
        ln -nfs nicerXti__nongrp.fits ni${My_Nicer_ID}.pha
        rm -f ni${My_Nicer_ID}_bkg.pha

        # mkf3存在確認
        if [[ -f $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf3 ]]; then
            :
        elif [[ -f $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf2 ]]; then
            # mkf2からmkf3作成
            niaddkp $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf2
        elif [[ -f $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf.gz ]]; then
            # mkf -> mkf2
            niprefilter2 indir=${My_Nicer_Dir} infile=${My_Nicer_Dir}/auxil/ni${My_Nicer_ID}.mkf.gz outfile=${My_Nicer_Dir}/auxil/ni${My_Nicer_ID}.mkf2
            # mkf2 -> mkf3
            niaddkp $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf2
        else
            # mkfもないなら無理
            continue
        fi

        # bk作成
        nibkgestimator ni${My_Nicer_ID}.pha $My_Nicer_Dir/auxil/ni${My_Nicer_ID}.mkf3 --bkg_evt $CALDB/data/nicer/xti/pcf/30nov18targskc_enhanced.evt
        # 名前を調整
        #mv ni${My_Nicer_ID}.pha ni${My_Nicer_ID}_nongrp.fits
        mv ni${My_Nicer_ID}_bkg.pha nicerXti__esti_bkg.fits
    done
fi

# nibackgen3C50
# NIBACKGEN3C50_MODEL_PATH の判定
if [[ -x $(which nibackgen3C50) ]] && [[ -x ${NIBACKGEN3C50_MODEL_PATH} ]]; then
    ni3C50_bin_path=$(cd $(dirname $(readlink -f $(which nibackgen3C50))); pwd )
    ni3C50_bkg_path=${ni3C50_bin_path}/../
    obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
    for My_Nicer_ID in ${obs_dirs[@]}; do

        My_Nicer_Dir=$My_Nicer_D/$My_Nicer_ID
        if [[ ! -r $My_Nicer_Dir/xti/event_cl/fit ]]; then continue; fi

        cd $My_Nicer_Dir/xti/event_cl/fit

        #mkdir $My_Nicer_Dir/xti/out3C50 -p
        #mv $My_Nicer_Dir/xti/out3C50
        ln -nfs nicerXti__nongrp.fits nibackgen3C50_tot.pi
        rm nibackgen3C50_bkg.pi -f

        nibackgen3C50 rootdir=$My_Nicer_D obsid=$My_Nicer_ID bkgdir=${NIBACKGEN3C50_MODEL_PATH} #~/mylib/soft/nicer/nibackgen3C50/bg_model_3C50_RGv5

        #mv nibackgen3C50_tot.pi ni3C50_${My_Nicer_ID}_nongrp.fits
        mv nibackgen3C50_bkg.pi nicerXti__3C50_bkg.fits

    done
fi


cd $My_Nicer_D
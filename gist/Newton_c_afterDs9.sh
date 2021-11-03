# _Newton_c_afterDs9
# _Newton_4_regionFilter
## region filter
echo ${My_Newton_D:=$(pwd)}
cd $My_Newton_D

if [[ x == x$(alias sas 2>/dev/null) ]]; then
    echo "Error: alias sas is not defined."
    kill -INT $$
fi
sas
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do

    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
    cd $My_Newton_Dir/fit

    declare -A spchmax=(["mos1"]=11999 ["mos2"]=11999 ["pn"]=20479)
    all_cams_tmp=($(ls *_filt_time.fits |
        sed -r -n "s/^.*(mos1|mos2|pn)_filt_time.fits$/\1/p"))
    for cam in ${all_cams_tmp[@]}; do
        # for source
        ds9 ${cam}_filt_time.fits -regions load ${cam}.reg -regions system physical \
            -regions save tmp.reg -exit
        coor_arg=$(cat tmp.reg | grep circle |
            grep -v "# background" |
            sed -r -n "s/^.*circle\((.*)\).*$/\1/p")

        rm ${cam}__nongrp.fits -f
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
            -regions save tmp.reg -exit
        coor_arg=$(cat tmp.reg | grep circle |
            grep "# background" |
            sed -r -n "s/^.*circle\((.*)\).*$/\1/p")
        rm ${cam}__bkg.fits -f
        evselect table=${cam}_filt_time.fits energycolumn="PI" \
            withfilteredset=yes filteredset=bkg_filtered.fits \
            keepfilteroutput=yes filtertype="expression" \
            expression="((X,Y) in CIRCLE(${coor_arg}))" \
            withspectrumset=yes spectrumset=${cam}__bkg.fits \
            spectralbinsize=5 withspecranges=yes \
            specchannelmin=0 specchannelmax=${spchmax[$cam]}
    done
done
cd $My_Newton_D
# _Newton_5_lightCurve
## light curve
echo ${My_Newton_D:=$(pwd)}
cd $My_Newton_D

if [[ x == x$(alias sas 2>/dev/null) ]]; then
    echo "Error: alias sas is not defined."
    kill -INT $$
fi
sas
mkdir $My_Newton_D/lc -p
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do

    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF

    cd $My_Newton_Dir/fit
    all_cams_tmp=($(ls *_filt_time.fits |
        sed -r -n "s/^.*(mos1|mos2|pn)_filt_time.fits$/\1/p"))
    for cam in ${all_cams_tmp}; do
        ds9 ${cam}_filt_time.fits -regions load ${cam}.reg \
            -regions system physical -regions save tmp.reg -exit
        coor_arg=$(cat tmp.reg | grep circle |
            grep -v "# background" |
            sed -r -n "s/^.*circle\((.*)\).*$/\1/p")

        evselect table=${cam}_filt_time.fits withrateset=yes \
            rateset=${My_Newton_D}/lc/newton_${cam}_lc_src_${My_Newton_ID}.fits \
            maketimecolumn=yes timecolumn=TIME \
            timebinsize=100 makeratecolumn=yes \
            expression="((X,Y) in CIRCLE(${coor_arg}))&&(PI in [200:10000])"
    done
done
cd $My_Newton_D

# _Newton_6_genRmfArf
## rmf, arf作成
echo ${My_Newton_D:=$(pwd)}
cd $My_Newton_D

if [[ x == x$(alias sas 2>/dev/null) ]]; then
    echo "Error: alias sas is not defined."
    kill -INT $$
fi
sas
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do
    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
    cd $My_Newton_Dir/fit
    all_cams_now=($(find . -name "*__nongrp.fits" -printf "%f\n" |
        sed -r -n "s/^.*(mos1|mos2|pn)__nongrp.fits$/\1/p"))

    for cam in ${all_cams_now[@]}; do
        rm ${cam}__rmf.fits ${cam}__arf.fits -f
        export SAS_CCF=$My_Newton_Dir/ccf.cif
        rmfgen rmfset=${cam}__rmf.fits spectrumset=${cam}__nongrp.fits
        arfgen arfset=${cam}__arf.fits spectrumset=${cam}__nongrp.fits \
            withrmfset=yes rmfset=${cam}__rmf.fits withbadpixcorr=yes \
            badpixlocation=${cam}_filt_time.fits
    done
done
cd $My_Newton_D

# _Newton_7_addascaspec
## addascaspec
echo ${My_Newton_D:=$(pwd)}
cd $My_Newton_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do

    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
    cd $My_Newton_Dir/fit

    all_cams_now=($(ls *_nongrp.fits | sed -r -n "s/^.*(mos1|mos2|pn)_.*_nongrp.fits$/\1/p"))
    for cam in ${all_cams_now[@]}; do
        find . -name "${cam}__*.fits" |
            rename "s/^${cam}__/newton_${cam}_${My_Newton_ID}_/" -f
    done

    if [[ -n $(echo ${all_cams_now} | grep mos) ]]; then
        mos_cams=($(echo ${all_cams_now[@]//pn/} | sed -r -n "s/\s*(mos1|mos2)\s*/\1 /gp"))
        cat <<EOF >tmp_fi.add
$(for mos_cam in ${mos_cams[@]}; do echo "newton_${mos_cam}_${My_Newton_ID}_pi.fits "; done)
$(for mos_cam in ${mos_cams[@]}; do echo "newton_${mos_cam}_${My_Newton_ID}_bkg.fits "; done)
$(for mos_cam in ${mos_cams[@]}; do echo "newton_${mos_cam}_${My_Newton_ID}_rmf.fits "; done)
$(for mos_cam in ${mos_cams[@]}; do echo "newton_${mos_cam}_${My_Newton_ID}_arf.fits "; done)
EOF
        rm -f newton_mos12_${My_Newton_ID}_nongrp.fits \
            newton_mos12_${My_Newton_ID}_rmf.fits newton_mos12_${My_Newton_ID}_bkg.fits
        addascaspec tmp_fi.add newton_mos12_${My_Newton_ID}_nongrp.fits \
            newton_mos12_${My_Newton_ID}_rmf.fits newton_mos12_${My_Newton_ID}_bkg.fits
    fi
done

cd $My_Newton_D
# _Newton_8_editHeader
## edit header
echo ${My_Newton_D:=$(pwd)}
cd $My_Newton_D

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do
    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir/fit ]]; then continue; fi
    cd $My_Newton_Dir/fit

    all_cams_tmp2=($(find . -name "newton_*_nongrp.fits"  -printf "%f\n" |
        sed -r -n "s/^newton_(mos1|mos2|mos12|pn)_${My_Newton_ID}_nongrp.fits$/\1/p"))
    for cam in ${all_cams_tmp2[@]}; do
        nongrp_name=newton_${cam}_${My_Newton_ID}_nongrp.fits
        rm ${grp_name} -f

        if [[ $cam == "mos12" ]]; then

            # edit header for nongrp
            oldName=newton_mos1_${My_Newton_ID}_pi.fits
            newName=$nongrp_name

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

            for key in ${cp_keys[@]} ${cp_keys2[@]}; do
                orig_val=$(fkeyprint infile="${oldName}+0" keynam="${key}" |
                    grep "${key}\s*=" |
                    sed -r -n "s/^.*${key}\s*=\s*(.*)\s*\/.*$/\1/p")

                tr_keys[$key]="${orig_val}"
            done

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile=${newName}+1 \
                    keyword="${key}" add=yes
            done

        else
            # for pn, mos1, mos2
            declare -A tr_keys=(
                ["BACKFILE"]=newton_${cam}_${My_Newton_ID}_bkg.fits
                ["RESPFILE"]=newton_${cam}_${My_Newton_ID}_rmf.fits
                ["ANCRFILE"]=newton_${cam}_${My_Newton_ID}_arf.fits)

            for key in ${!tr_keys[@]}; do
                fparkey value="${tr_keys[$key]}" \
                    fitsfile=${nongrp_name}+0 \
                    keyword="${key}" add=yes
            done
        fi

    done
done

cd $My_Newton_D

# _Newton_9_grppha
## grppha
declare -A gnums=(["pn"]=50 ["mos12"]=50 ["mos1"]=50 ["mos2"]=50) # arg
echo ${My_Newton_D:=$(pwd)}
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

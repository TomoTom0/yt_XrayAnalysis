# _Newton_c_afterDs9
# _Newton_4_regionFilter
## region filter
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
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
# _Newton_5_lightCurve
## light curve
declare -A pis=(["mos1"]="PI in [200:12000]" ["mos2"]="PI in [200:12000]" ["pn"]="PI in [200:15000]") # arg
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
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

# _Newton_6_genRmfArf
## rmf, arf作成
FLAG_rmf=true # arg
FLAG_arf=true # arg
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
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

# _Newton_7_addascaspec
## addascaspec
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
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
# _Newton_8_editHeader
## edit header
FLAG_minimum=false # arg
FLAG_strict=false # arg
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
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

# _Newton_9_grppha
## grppha
declare -A gnums=(["pn"]=50 ["mos12"]=50 ["mos1"]=30 ["mos2"]=30) # arg
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
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

# _Newton_10_fitDirectory
## fitディレクトリにまとめ
FLAG_hardCopy=false # arg
FLAG_symbLink=false # arg
tmp_prefix="newton_" # arg
    declare -g My_Newton_D=${My_Newton_D:=$(pwd)} 
fi
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
# _Newton_4_regionFilter
## region filter
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Newton_D=${My_Newton_D:=$(pwd)} 
else 
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
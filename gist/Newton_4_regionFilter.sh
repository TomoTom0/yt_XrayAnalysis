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
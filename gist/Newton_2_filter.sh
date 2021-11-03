# _Newton_2_filter
## evselectでfiterをかけたfits作成
declare -A pis=(["mos1"]="PI in [200:12000]" ["mos2"]="PI in [200:12000]" ["pn"]="PI in [200:15000]") # arg
declare -A pis_hard=(["mos1"]="PI > 10000" ["mos2"]="PI > 10000" ["pn"]="PI in [10000:12000]") # arg
declare -A rates=(["mos1"]=0.35 ["mos2"]=0.35 ["pn"]=0.4) # arg
echo ${My_Newton_D:=$(pwd)}
cd $My_Newton_D
declare -A xmms=(["mos1"]="#XMMEA_EM" ["mos2"]="#XMMEA_EM" ["pn"]="#XMMEA_EP")

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

    all_cams_tmp=($(ls *.fits | sed -r -n "s/^.*(mos1|mos2|pn).fits$/\1/p"))
    for cam in ${all_cams_tmp[@]}; do
        evselect table=${cam}.fits withfilteredset=yes \
            expression="(PATTERN <= 12)&&(${pis[$cam]})&&${xmms[$cam]}" \
            filteredset=tmp_${cam}_filt.fits filtertype=expression \
            keepfilteroutput=yes \
            updateexposure=yes filterexposure=yes

        evselect table=${cam}.fits withrateset=yes \
            rateset=tmp_${cam}_lc_hard.fits \
            maketimecolumn=yes timecolumn=TIME timebinsize=100 makeratecolumn=yes \
            expression="(PATTERN == 0)&&(${pis_hard[$cam]})&&${xmms[$cam]}"

        tabgtigen table=tmp_${cam}_lc_hard.fits gtiset=gtiset.fits \
            timecolumn=TIME \
            expression="(RATE <= ${rates[$cam]})"

        evselect table=tmp_${cam}_filt.fits withfilteredset=yes \
            expression="GTI(gtiset.fits,TIME)" filteredset=${cam}_filt_time.fits \
            filtertype=expression keepfilteroutput=yes \
            updateexposure=yes filterexposure=yes
    done

done
cd $My_Newton_D

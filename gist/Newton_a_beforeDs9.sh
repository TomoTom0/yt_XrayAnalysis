# _Newton_a_beforeDs9
# _Newton_1_pipeline
## はじめの処理
all_cams=(mos1 mos2 pn) # arg
FLAG_clean=false # arg
declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
cd $My_Newton_D

if [[ x == x$(alias sas 2>/dev/null) ]]; then
    echo "Error: alias sas is not defined."
    kill -INT $$
fi
sas
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Newton_ID in ${obs_dirs[@]}; do
    My_Newton_Dir=$My_Newton_D/$My_Newton_ID/ODF
    if [[ ! -r $My_Newton_Dir ]]; then continue; fi
    cd $My_Newton_Dir

    find . -name "*.gz" | xargs gunzip
    export SAS_ODF=$My_Newton_D/$My_Newton_ID/ODF &&
        rm ccf.cif *SUM.SAS -f && cifbuild # make ccf.cif
    if [[ ! -r ccf.cif ]]; then
        echo "Error occured in cifbuild"
        kill -INT $$
    fi
    export SAS_CCF=$My_Newton_Dir/ccf.cif &&
        rm *SUM.SAS -f && odfingest # make *SUM.SAS
    if [[ x == x$(find . -name "*SUM.SAS" -printf 1) ]]; then
        echo "Error occured in odfingest"
        kill -INT $$
    fi
    _SAS_ODF_tmps=($(ls $My_Newton_Dir/*SUM.SAS))
    export SAS_ODF=${_SAS_ODF_tmps[-1]}
    rm -f *_EMOS[12]_*_ImagingEvts.ds && emproc
    if [[ x11 != x$(find . -name "*_EMOS[12]_*_ImagingEvts.ds" -printf 1) ]]; then
        echo "Error occured in emproc"
        kill -INT $$
    fi
    rm -f *_EPN_*_ImagingEvts.ds && epproc
    if [[ x == x$(find . -name "*_EPN_*_ImagingEvts.ds" -printf 1) ]]; then
        echo "Error occured in epproc"
        kill -INT $$
    fi
    if [[ "${FLAG_clean:=false}" == "true" ]]; then
        rm $My_Newton_Dir/fit -rf
    fi
    mkdir $My_Newton_Dir/fit -p

    cp *_EMOS1_*_ImagingEvts.ds fit/mos1.fits -f
    cp *_EMOS2_*_ImagingEvts.ds fit/mos2.fits -f
    cp *_EPN_*_ImagingEvts.ds fit/pn.fits -f

done
cd $My_Newton_D

# _Newton_2_filter
## evselectでfiterをかけたfits作成
declare -A pis=(["mos1"]="PI in [200:12000]" ["mos2"]="PI in [200:12000]" ["pn"]="PI in [200:15000]") # arg
declare -A pis_hard=(["mos1"]="PI > 10000" ["mos2"]="PI > 10000" ["pn"]="PI in [10000:12000]") # arg
declare -A rates=(["mos1"]=0.35 ["mos2"]=0.35 ["pn"]=0.4) # arg
declare -g My_Newton_D=${My_Newton_D:=$(pwd)}
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

    all_cams_tmp=($(find . -name "*.fits" -printf "%f\n" | sed -r -n "s/^(mos1|mos2|pn).fits$/\1/p"))
    for cam in ${all_cams_tmp[@]}; do
        rm tmp_${cam}_filt.fits -f &&
            evselect table=${cam}.fits withfilteredset=yes \
            expression="(PATTERN <= 12)&&(${pis[$cam]})&&${xmms[$cam]}" \
            filteredset=tmp_${cam}_filt.fits filtertype=expression \
            keepfilteroutput=yes \
            updateexposure=yes filterexposure=yes

        rm tmp_${cam}_lc_hard.fits -f &&
            evselect table=${cam}.fits withrateset=yes \
            rateset=tmp_${cam}_lc_hard.fits \
            maketimecolumn=yes timecolumn=TIME timebinsize=100 makeratecolumn=yes \
            expression="(PATTERN == 0)&&(${pis_hard[$cam]})&&${xmms[$cam]}"

        rm ${cam}_gti.fits -f &&
            tabgtigen table=tmp_${cam}_lc_hard.fits gtiset=${cam}_gti.fits \
            timecolumn=TIME \
            expression="(RATE <= ${rates[$cam]})"

        rm ${cam}_filt_time.fits -f &&
            evselect table=tmp_${cam}_filt.fits withfilteredset=yes \
            expression="GTI(${cam}_gti.fits,TIME)" filteredset=${cam}_filt_time.fits \
            filtertype=expression keepfilteroutput=yes \
            updateexposure=yes filterexposure=yes
    done

done
cd $My_Newton_D

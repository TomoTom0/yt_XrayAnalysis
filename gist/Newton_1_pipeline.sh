# _Newton_1_pipeline
## はじめの処理
all_cams=(mos1 mos2 pn) # arg
FLAG_clean=false # arg
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

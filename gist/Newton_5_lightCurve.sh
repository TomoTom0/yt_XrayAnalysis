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

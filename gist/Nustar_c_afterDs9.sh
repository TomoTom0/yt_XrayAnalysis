# _Nustar_c_afterDs9
# _Nustar_3_products
## nuproducts
declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} # 未定義時に代入
cd $My_Nustar_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir ]]; then continue; fi

    cd $My_Nustar_Dir

    rm $My_Nustar_Dir/fit/* -rf &&
        mkdir $My_Nustar_Dir/fit -p
    for cam in A B; do
        nuproducts \
            srcregionfile=$My_Nustar_Dir/out/src${cam}.reg \
            bkgregionfile=$My_Nustar_Dir/out/bkg${cam}.reg \
            indir=$My_Nustar_Dir/out \
            outdir=$My_Nustar_Dir/fit \
            instrument=FPM${cam} \
            steminputs=nu${My_Nustar_ID} \
            bkgextract=yes \
            clobber=yes
    done

done
cd $My_Nustar_D
# _Nustar_4_addascaspec
## addascaspec
declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} # 未定義時に代入
cd $My_Nustar_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir/fit ]]; then continue; fi

    cd $My_Nustar_Dir/fit

    cat <<EOF >tmp_fi.add
nu${My_Nustar_ID}A01_sr.pha nu${My_Nustar_ID}B01_sr.pha
nu${My_Nustar_ID}A01_bk.pha nu${My_Nustar_ID}B01_bk.pha
nu${My_Nustar_ID}A01_sr.arf nu${My_Nustar_ID}B01_sr.arf
nu${My_Nustar_ID}A01_sr.rmf nu${My_Nustar_ID}B01_sr.rmf
EOF

    rm AB_${My_Nustar_ID}_nongrp.fits \
        AB_${My_Nustar_ID}_rsp.fits \
        AB_${My_Nustar_ID}_bkg.fits -f
    addascaspec tmp_fi.add \
        AB_${My_Nustar_ID}_nongrp.fits \
        AB_${My_Nustar_ID}_rsp.fits \
        AB_${My_Nustar_ID}_bkg.fits
done
cd $My_Nustar_D
# _Nustar_5_editHeader
## edit header
FLAG_minimum=false # arg
FLAG_strict=false # arg
origSrc=nu%OBSID%A01_sr.pha # arg
origBkg=nu%OBSID%A01_bk.pha # arg
declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} # 未定義時に代入
cd $My_Nustar_D
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
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir/fit ]]; then continue; fi

    cd $My_Nustar_Dir/fit
    nongrp_name=AB_${My_Nustar_ID}_nongrp.fits

    ### edit header for spectrum file
    _oldName_tmp=${origSrc/\%OBSID%/${My_Nustar_ID}}
    if [[ -r ${_oldName_tmp} ]]; then
        oldName=${_oldName_tmp}
    else
        oldName=nu${My_Nustar_ID}A01_sr.pha
    fi
    newName=$nongrp_name
    oldExtNum=$(_ObtainExtNum $oldName SPECTRUM)
    newExtNum=$(_ObtainExtNum $newName SPECTRUM)

    #### same values
    cp_keys=(TELESCOP OBS_ID TARG_ID OBJECT RA_OBJ
        DEC_OBJ RA_NOM DEC_NOM RA_PNT DEC_PNT PA_PNT
        EQUINOX RADECSYS TASSIGN TIMESYS MJDREFI MJDREFF
        TIMEREF CLOCKAPP TIMEUNIT TSTOP DATE-OBS DATE-END
        ORIGIN DATETLM TLM2FITS SOFTVER CALDBVER USER
        TIMEZERO DEADAPP TSORTKEY NUFLAG ABERRAT FOLOWSUN
        DSTYP1 DSVAL1 NUPSDOUT DEPTHCUT OBSMODE HDUNAME
        AXLEN1 AXLEN2 CONTENT WMREBIN OBS-MODE SKYBIN
        PIXSIZE WMAPFIX DSTYP2 DSREF2 DSVAL2 CTYPE1 DRPIX1
        CRVAL1 CDELT1 DDELT1 CTYPE2 DRPIX2 CRVAL2 CDELT2
        DDELT2 WCSNAMEP WCSTY1P LTM1_1 CTYPE1P CRPIX1P
        CDELT1P WCSTY2P LTM2_2 CTYPE2P CRPIX2P CDELT2P
        OPTIC1 OPTIC2 HBBOX1 HBBOX2 REFXCTYP REFXCRPX
        REFXCRVL REFXCDLT REFYCTYP REFYCRPX REFYCRVL REFYCDLT)

    #### near values
    cp_keys2=(INSTRUME TSTART TELAPSE ONTIME LIVETIME
        MJD-OBS FILIN001 DEADC NPIXSOU CRPIX1 CRPIX2 LTV1
        CRVAL1P LTV2 CRVAL2P BBOX1 BBOX2 X-OFFSET
        Y-OFFSET TOTCTS)

    if [[ ${FLAG_strict:=false} == "true" ]]; then
        cp_keys2=()
    fi
    if [[ ${FLAG_minimum:=false} == "true" ]]; then
        cp_keys=()
        cp_keys2=()
    fi

    declare -A tr_keys=(
        ["BACKFILE"]="AB_${My_Nustar_ID}_bkg.fits"
        ["RESPFILE"]="AB_${My_Nustar_ID}_rsp.fits"
    )

    for key in ${cp_keys[@]} ${cp_keys2[@]}; do
        orig_val=$(fkeyprint infile="${oldName}+${oldExtNum}" keynam="${key}" |
            grep "${key}\s*=" |
            sed -r -n "s/^.*${key}\s*=\s*(.*)\s*\/.*$/\1/p")

        tr_keys[$key]="${orig_val}"
    done

    for key in ${!tr_keys[@]}; do
        fparkey value="${tr_keys[$key]}" \
            fitsfile="${newName}+${newExtNum}" \
            keyword="${key}" add=yes
    done

    ### edit header for bkg file
    _oldName_tmp=${origBkg/\%OBSID%/${My_Nustar_ID}}
    if [[ -r ${_oldName_tmp} ]]; then
        oldName=${_oldName_tmp}
    else
        oldName=nu${My_Nustar_ID}A01_bk.pha
    fi
    newName=AB_${My_Nustar_ID}_bkg.fits
    oldExtNum=$(_ObtainExtNum $oldName SPECTRUM)
    newExtNum=$(_ObtainExtNum $newName SPECTRUM)

    #### same values
    cp_keys=(TELESCOP OBS_ID TARG_ID OBJECT RA_OBJ
        DEC_OBJ RA_NOM DEC_NOM RA_PNT DEC_PNT PA_PNT
        EQUINOX RADECSYS TASSIGN TIMESYS MJDREFI MJDREFF
        TIMEREF CLOCKAPP TIMEUNIT TSTART TSTOP TELAPSE
        DATE-OBS DATE-END ORIGIN CREATOR DATETLM TLM2FITS
        SOFTVER CALDBVER MJD-OBS USER FILIN001 TIMEZERO
        DEADAPP TSORTKEY NUFLAG ABERRAT FOLOWSUN DSTYP1
        DSVAL1 NPIXSOU NUPSDOUT DEPTHCUT OBSMODE HDUNAME
        AXLEN1 AXLEN2 CONTENT WMREBIN OBS-MODE SKYBIN
        PIXSIZE WMAPFIX DSTYP2 DSREF2 DSVAL2 CTYPE1 CRPIX1
        DRPIX1 CRVAL1 CDELT1 DDELT1 CTYPE2 CRPIX2 DRPIX2
        CRVAL2 CDELT2 DDELT2 WCSNAMEP WCSTY1P LTV1 LTM1_1
        CTYPE1P CRPIX1P CRVAL1P CDELT1P WCSTY2P LTV2
        LTM2_2 CTYPE2P CRPIX2P CRVAL2P CDELT2P OPTIC1
        OPTIC2 BBOX1 BBOX2 HBBOX1 HBBOX2 X-OFFSET Y-OFFSET
        REFXCTYP REFXCRPX REFXCRVL REFXCDLT REFYCTYP
        REFYCRPX REFYCRVL REFYCDLT)

    #### near values
    cp_keys2=(INSTRUME DATE ONTIME LIVETIME DEADC)

    if [[ ${FLAG_strict:=false} == "true" ]]; then
        cp_keys2=()
    fi
    if [[ ${FLAG_minimum:=false} == "true" ]]; then
        cp_keys=()
        cp_keys2=()
    fi

    declare -A tr_keys=()

    for key in ${cp_keys[@]} ${cp_keys2[@]}; do
        orig_val=$(fkeyprint infile="${oldName}+${oldExtNum}" keynam="${key}" |
            grep "${key}\s*=" |
            sed -r -n "s/^.*${key}\s*=\s*(.*)\s*\/.*$/\1/p")

        tr_keys[$key]="${orig_val}"
    done

    for key in ${!tr_keys[@]}; do
        fparkey value="${tr_keys[$key]}" \
            fitsfile="${newName}+${newExtNum}" \
            keyword="${key}" add=yes
    done
done
cd $My_Nustar_D
# _Nustar_6_grppha
## grppha
gnum=50 # arg
declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} # 未定義時に代入
cd $My_Nustar_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir/fit ]]; then continue; fi
    cd $My_Nustar_Dir/fit/
    if [[ ${gnum} -le 0 ]]; then continue; fi
    grp_name=AB_${My_Nustar_ID}_grp${gnum}.fits
    rm ${grp_name} -f
    cat <<EOF | bash
grppha infile=AB_${My_Nustar_ID}_nongrp.fits outfile=${grp_name} clobber=true
group min ${gnum}
exit !${grp_name}
EOF
done
cd $My_Nustar_D
# _Nustar_7_fitDirectory
## fitディレクトリにまとめ
FLAG_hardCopy=false # arg
FLAG_symbLink=false # arg
tmp_prefix="AB_" # arg
declare -g My_Nustar_D=${My_Nustar_D:=$(pwd)} # 未定義時に代入
cd $My_Nustar_D

obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
mkdir -p $My_Nustar_D/fit $My_Nustar_D/../fit/
for My_Nustar_ID in ${obs_dirs[@]}; do
    cp $My_Nustar_D/$My_Nustar_ID/fit/${tmp_prefix}* $My_Nustar_D/fit/ -f
done
### remove the files with the same name as new files
find $My_Nustar_D/fit/ -name "${tmp_prefix}*.*" \
    -type f -printf "%f\n" |
    xargs -n 1 -i rm -f $My_Nustar_D/../fit/{}
### remove broken symbolic links
find -L $My_Nustar_D/../fit/ -type l -delete
### generate symbolic links
ln -s $My_Nustar_D/fit/${tmp_prefix}*.* $My_Nustar_D/../fit/
cd $My_Nustar_D
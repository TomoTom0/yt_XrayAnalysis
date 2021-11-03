# _Nustar_5_editHEader
## edit header
echo ${My_Nustar_D:=$(pwd)} # 未定義時に代入
cd $My_Nustar_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9]))
for My_Nustar_ID in ${obs_dirs[@]}; do

    My_Nustar_Dir=$My_Nustar_D/$My_Nustar_ID
    if [[ ! -r $My_Nustar_Dir/fit ]]; then continue; fi

    cd $My_Nustar_Dir/fit
    nongrp_name=AB_${My_Nustar_ID}_nongrp.fits

    ### edit header for spectrum file
    oldName=nu${My_Nustar_ID}A01_sr.pha
    newName=$nongrp_name

    ### same values
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

    ### near values
    cp_keys2=(INSTRUME TSTART TELAPSE ONTIME LIVETIME
        MJD-OBS FILIN001 DEADC NPIXSOU CRPIX1 CRPIX2 LTV1
        CRVAL1P LTV2 CRVAL2P BBOX1 BBOX2 X-OFFSET
        Y-OFFSET TOTCTS)

    declare -A tr_keys=(
        ["BACKFILE"]="AB_${My_Nustar_ID}_bkg.fits"
        ["RESPFILE"]="AB_${My_Nustar_ID}_rsp.fits"
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

    ### edit header for bkg file
    oldName=nu${My_Nustar_ID}A01_bk.pha
    newName=AB_${My_Nustar_ID}_bkg.fits

    ### same values
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

    ### near values
    cp_keys2=(INSTRUME DATE ONTIME LIVETIME DEADC)

    declare -A tr_keys=()

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
done
cd $My_Nustar_D
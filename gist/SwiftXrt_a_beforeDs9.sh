# _SwiftXrt_a_beforeDs9
# _SwiftXrt_1_pipeline
## pipeline
if [[ $(declare --help | grep -c -o -E "\-g\s+create global variables") -eq 0 ]]; then 
    My_Swift_D=${My_Swift_D:=$(pwd)} 
else 
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
fi
cd $My_Swift_D
obs_dirs=($(find . -maxdepth 1 -type d -printf "%P\n" | grep ^[0-9] | sort))
for My_Swift_ID in ${obs_dirs[@]}; do

    My_Swift_Dir=$My_Swift_D/$My_Swift_ID
    if [[ ! -r $My_Swift_Dir ]]; then continue; fi

    cd $My_Swift_Dir
    rm $My_Swift_Dir/xrt/output -rf
    mkdir $My_Swift_Dir/xrt/output -p
    xrtpipeline indir=$My_Swift_Dir \
        outdir="$My_Swift_Dir//xrt/output" \
        steminputs=sw${My_Swift_ID} \
        srcra=OBJECT srcdec=OBJECT clobber=yes
done
cd $My_Swift_D
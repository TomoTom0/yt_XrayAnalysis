# _SwiftXrtBuild_1_downloadData
## download Data
url="" # arg
    declare -g My_Swift_D=${My_Swift_D:=$(pwd)} 
fi
cd $My_Swift_D
if [[ "x${url}" != "x" ]]; then
    prod_ID=$(echo $url | sed -r -n "s/^.*\/USERPROD_([0-9]+)\/.*$/\1/p")
    ext=${url##*.}
    My_Swift_Dir=$My_Swift_D/xrt/xrt_build_${prod_ID}
    mkdir $My_Swift_Dir -p
    if [[ ! -r $My_Swift_Dir ]]; then continue; fi
    cd $My_Swift_Dir
    rm $My_Swift_Dir/* -rf

    tmp_file=tmp.${ext}
    wget $url --no-check-certificate -O $tmp_file
    tar xvf $tmp_file

    if [[ "x${ext}" == "xtar" ]]; then
        ## per ObsID
        cd $My_Swift_Dir/USERPROD_${prod_ID}/spec
        find . -name "*.gz" | xargs -n 1 tar xvf
    elif [[ "x${ext}" == "xgz" ]]; then
        ## Other Cases
        find . -name "*.gz" | xargs -n 1 tar xvf
    fi
fi
cd $My_Swift_D
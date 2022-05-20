#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd)

if [[ -z ${flagsIn[dry]} ]]; then
    python3 ${dir_path}/restruct.py
fi

bash ${dir_path}/push2gist_simple.sh


#!/bin/bash

dir_path=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
setup_path=$dir_path/../src/bin/setup.sh
if [[ -r $setup_path ]]; then
    source $setup_path
fi
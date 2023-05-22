#!/bin/bash

dir_path=$( cd $(dirname ${BASH_SOURCE:-$0}); pwd)

python3 ${dir_path}/restruct.py

bash ${dir_path}/push2gist_simple.sh


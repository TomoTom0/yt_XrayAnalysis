#!/bin/bash

dir_path=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

echo "" >> ~/.bashrc
echo "# yt_XrayAnalysis" >> ~/.bashrc
echo "if [[ -r ${dir_path}/bin/setup.sh ]]; then" >> ~/.bashrc
echo "    source ${dir_path}/bin/setup.sh" >> ~/.bashrc
echo "fi" >> ~/.bashrc
#!/usr/bin/python3

import os
import re
import shutil
import glob2

dir_root=os.path.dirname(__file__) if os.path.dirname(__file__)!="" else ""
output_dir=(f"{dir_root}/" if dir_root!="" else "")  +"../tmp"

def extractScript():
    output_dir=f"{dir_root}/../tmp"
    shutil.rmtree(output_dir)
    os.makedirs(output_dir, exist_ok=True)
    script_paths=glob2.glob(f"{dir_root}/*/yt_*.sh", recursive=True)
    for script_path in script_paths:
        with open(script_path) as f:
            lines=[re.sub("^\s{4}", "", s[:-1]) for s in f.readlines()]
        status=0
        valid_funcs=[]
        for line in lines:
            if status==0 and line.startswith("function _"):
                funcName=[s[9:-1] for s in re.findall(r"function _[^\(]+\(", line)][0]
                tmp_dict={"name":funcName, "content":["# "+funcName]}
                valid_funcs.append(tmp_dict)
                status=1
            elif status==1 and re.findall(r"^\s*#", line)!=[]:
                valid_funcs[-1]["content"].append(line)
                status=2
            elif status==2 and re.findall(r"^\s*# args: ", line)!=[]:
                tmp_line=line.replace("# args: ", "")
                valid_funcs[-1]["content"].append(tmp_line + " # arg")
            elif status==2 and re.findall(r"^\s*if \[\[ \$\(declare --help \| grep -c -o -E \"\\\-g\\s\+create global variables\"\) -eq 0 \]\]; then", line)!=[]:
                valid_funcs[-1]["content"].append(line)
                status=10
            elif status==10:
                valid_funcs[-1]["content"].append(line)
                if re.findall(r"^\s*fi", line)!=[]:
                    status=20
            elif status==20 and re.findall(r"^\s*if \[\[ x\$\{FUNCNAME\} != x \]\]; then return 0; fi", line)!=[]:
                status=0
            elif status==20:
                valid_funcs[-1]["content"].append(line)


        for tmp_dict in valid_funcs:
            output_path=output_dir+"/"+tmp_dict["name"][1:]+".sh"
            with open(output_path, "w") as f:
                f.write("\n".join(tmp_dict["content"]))

def combineScript():
    output_dir=f"{dir_root}/../tmp"
    os.makedirs(output_dir, exist_ok=True)
    script_paths=glob2.glob(f"{dir_root}/*/ytBlock_*.sh", recursive=True)
    extracted_files=glob2.glob(f"{output_dir}/*.sh", recursive=True)
    for script_path in script_paths:
        with open(script_path) as f:
            lines=[s.strip() for s in f.readlines()]
        status=0
        valid_funcs=[]
        for line in lines:
            if status==0 and line.startswith("function _"):
                funcName=[s[9:-1] for s in re.findall(r"function _[^\(]+\(", line)][0]
                tmp_dict={"name":funcName, "content":["# "+funcName]}
                valid_funcs.append(tmp_dict)
                status=10
                continue
            elif status==10 and re.findall(r"^\s*if \[\[ \$\(declare --help \| grep -c -o -E \"\\\-g\\s\+create global variables\"\) -eq 0 \]\]; then", line)!=[]:
                status=11
            elif status==11 and re.findall(r"^\s*fi", line)!=[]:
                status=20
            elif status==20 and re.findall(r"^yt_", line)!=[]:
                funcNameAlias=(re.findall(r"yt_\S+", line)+[""])[0]
                if len(funcNameAlias)==0:
                    continue
                funcNamePart=funcNameAlias[3:4].upper()+funcNameAlias[4:]+"_"
                func_path=([s for s in extracted_files if re.findall(funcNamePart, s)!=[]]+[""])[0]
                if len(func_path) == 0:
                    continue
                with open(func_path) as f:
                    conetnt_tmp=f.read()
                valid_funcs[-1]["content"].append(conetnt_tmp)
                continue
            elif status==20 and re.findall(r"return 0", line)!=[]:
                status=0

        for tmp_dict in valid_funcs:
            output_path=output_dir+"/"+tmp_dict["name"][1:]+".sh"
            with open(output_path, "w") as f:
                f.write("\n".join(tmp_dict["content"]))

def main():
    extractScript()
    combineScript()

if __name__ == "__main__":
    main()
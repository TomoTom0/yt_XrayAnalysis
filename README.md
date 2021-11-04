# yt_XrayAnalysis

bash scripts for X-ray analysis with heasoft

[TOC]
## Introduction

Coming Soon

This package is on the pre-alpha version.
Please remember there may be many problems.

## Install

In order to install, excute `install.sh`

```bash
./install.sh
```

or add the following content to `~/.bashrc` or `~/.bash_profile` 

```bash
## ~/.bashrc

# yt_XrayAnalysis
if [[ -r Path_Of_ytXrayAnalysis_Directory/bin/setup.sh ]]; then
    source Path_Of_ytXrayAnalysis_Directory/bin/setup.sh
fi

## repalce Path_Of_ytXrayAnalysis_Directory to the correct path
```

**HEASoft and CALDB must be installed**.

## Usage

### Commands
Basic commands in this package have the following structure:
| type| structure|example|comment|
|-|-|-|-|
|alias 1| `<prefix>_<mission>_<processNumber>` |`yt_newton_5`|`<mission>` sometimes accompanies the name of instrument.|
|alias 2|  `<prefix>_<mission>_<processName>` |`yt_newton_genRmfArf`||
|function|  `_<Mission>_<processNumber>_<processName>` |`_Newton_5_genRmfArf`|These aliases are linked to this function.|

There are some basic commands which can executed in succession, so they can be called from a combined command.

| type| structure|example|comment|
|-|-|-|-|
|alias 1| `<prefix>_<mission>__<processOrder>` |`yt_newton__a`| The underbar after `<mission>` are duplicated on purpose. |
|alias 2|  `<prefix>_<mission>_<processName>` |`yt_newton_beforeDs9`||
|function|  `_<Mission>_<processOrder>_<processName>` |`_Newton_a_beforeDs9`|These aliases are linked to this function|

In using the aliases, you can check the suggestion with inputting `<prefix>_<mission>`.


### Example

Comibg Soon.

## Features
### Gist & HackMD

The scripts are pushed to gist at the same time and they are linked to notes on HackMD.
You can read the guide of X-ray Analysis with the updated scripts.

### Paste to the terminal

The scripts in this package are written as they works if you paste them to the terminal instead of calling them as bash function,
so if you want to adjust or check the script, you can edit the script on the editor and paste it to the terminal.

Then you should use scripts on `gist/*.sh` because they are compiled in the more proper format.
In the compiled scripts, bash variables whose value you should change as the arguments are 
placed to the head of the block and appended with `# args` on the end of line.

### Missions

|mission|instrument|identifier|comment|
|-|-|-|-|
|XMM-Newton|EMOS, EPN|`newton`|SAS is required.|
|NuSTAR|FPM|`nustar`||
|Suzaku|XIS|`suzakuXis`||
|Suzaku|HXD|`suzakuHxd`||
|Swift|XRT|`swiftXrt`||
|Swift|XRT(Online build)|`swiftXrtOnline`|Coming soon|
|Swift|BAT|`swiftBat`|Coming soon|
|Swift|BAT(n-Month Catalog)|`swiftBatMonth`|Coming soon|
|Swift|UVOT|`swiftUvot`|Coming soon|
|Nicer|xis|`nicerXis`|Coming soon|




## Caution

Coming Soon
## Updates

Coming Soon

## Future Work

### the format of bash function

The bash functions in this package don't yet have the proper structure for help, options and arguments.

## Contact Me

Gmail: TomoIris427+GitHub@gmail.com

## LICENSE

MIT
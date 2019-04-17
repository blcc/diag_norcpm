#!/bin/bash
#################################################################################
##  diag_norcpm
##      This package is used to plot figures for ensembled seasonal prediction.
##      Development for NorCPM, but should suitable for CESM-like models.
##      Process:
##          
##                                            by Ping-Gin Chiu, start at 28Feb2019
#################################################################################

#--------------------------- case settings begin -----------------------
# plotCase: name of this plot
plotCase='seas-hind-V1c_19881015'
echo start plot $plotCase

# ensDataDirs: NorESM output data dirs, can use wildcards( * and ?  using bash)
#ensDataDirs=$(ls -d ~/NS9039K/shared/norcpm/cases/NorCPM/NorCPM_V2/ana_me_ICEC-SST-S-T-1980-2010/ana_19800115_me_mem0{1,2})
ensDataDirs=$(ls -d ~/NS9039K/shared/norcpm/cases/NorCPM/NorCPM_V1c/ana_19800115_me_hindcasts/ana_19800115_me_19881015/ana_19800115_me_19881015_mem??)

# plotRecipes: figures you want to plot, if none or empty means *.yml in Recipes/, Split with comma
#plotRecipes='02_test_recipes.yml'
#plotRecipes='03_AnoCor.yml'
plotRecipes=''

#--------------------------- case settings end -------------------------


# Machine related settings 
#--------------------------- machine settings begin -----------------------
## figures and webpages output directory, default is "$(pwd)/${plotCase}"
outputDir="$(pwd)/${plotCase}"

## observation or reanalysis data to compare, not done yet, heavily depends on machine
obsDataDir='/cluster/projects/nn9039k/NorCPM/Obs'


## root directory of this package, sould contain doplot.py
diag_norcpm_Root="${HOME}/work/diag_norcpm"

## root directory of this package, sould contain doplot.py
defaultRecipe="${diag_norcpm_Root}/Defaults.yml"

## python used to run doplot.py, develop with python3.4, but other version should ok.
echo before module load
module -q purge
module -q load NCO/4.7.2-intel-2018a
module -q load CDO/1.9.3-intel-2018a
module -q load NCL/6.5.0-intel-2018a
module -q unload LibTIFF/4.0.9/GCCcore-6.4.0
module -q load Python/3.6.4-intel-2018a
PYTHON=$(which python)
NCL=$(which ncl)
#--------------------------- machine settings end -----------------------

# do plot
export plotCase ensDataDirs plotRecipes
export outputDir obsDataDir diag_norcpm_Root defaultRecipe
export PYTHON NCL
echo start doplot
"$PYTHON" "${diag_norcpm_Root}/doplot.py"

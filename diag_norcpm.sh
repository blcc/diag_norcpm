#!/bin/bash
#################################################################################
##  diag_norcpm
##      This package is used to plot figures for ensembled seasonal prediction.
##      Development for NorCPM.
##          
##                                            by Ping-Gin Chiu, start at 28Feb2019
##                                                                v2  at 23Apr2019
#################################################################################

#--------------------------- get data dir from argument -----------------------
## dirs as arguments, plot all figures
##      each dir in BASEDIR should contain members of simulation
##      if the member path: 
##              /path/to/model_ver/ana_19800115_me_hindcasts/ana_19800115_me_20090115/ana_19800115_me_20090115_mem09/atm/hist/
##      then the arguments should be:
##             /path/to/model_ver/ana_19800115_me_hindcasts
BASEDIR="${1}"
if [ -z "${BASEDIR}" ];then
    echo "$0 <hindcasts_dir>"
    exit
fi
BASEDIR="$(readlink -f ${BASEDIR}|head -n1)" ## make sure it is absolute path

#--------------------------- case settings begin -----------------------
# plotCase: name of this plot, get upper dirname
Dir=$(basename ${BASEDIR})
plotCase=$(basename $(dirname ${BASEDIR}))-${Dir} ## {model_ver}_{hindcasts}

# prefixRun: ana_19800115_me_  # 
RUNPRE=${Dir%hindcasts} # remove "hindcast" string
if [ -z "$(ls $BASEDIR/$RUNPRE*)" ]; then # if not, take first forecast run and remove tailling date
    RUNPRE=$(ls -d $BASEDIR/*_????????|head -n1)
    RUNPRE=$(basename $RUNPRE | sed "s/[0-9]\{8\}$//")
fi

# plotRecipes: figures you want to plot, if none or empty means *.yml in Recipes/, Split with comma
plotRecipes='mpiexm/A01_mpiexm_annualvar.yml'
plotRecipes='16_AnoCor_seaice_frac.yml'
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
export plotCase BASEDIR plotRecipes RUNPRE
export outputDir obsDataDir diag_norcpm_Root defaultRecipe
export PYTHON NCL
echo '================================= diag settings:'
echo "plotCase:    ${plotCase}"
echo "Data dir:    ${BASEDIR}"
echo "Case prefix: ${RUNPRE}"
echo "outputDir:   ${outputDir}"
echo '================================= '
"$PYTHON" "${diag_norcpm_Root}/doplot.py"

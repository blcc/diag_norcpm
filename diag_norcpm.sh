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
plotCase=norcpm_diag_01

# ensDataDirs: NorESM output data dirs, can use wildcards( * and ?  using bash)
ensDataDirs=$(ls -d /nird/home/pgchiu/NS9039K/shared/norcpm/cases/NorCPM/NorCPM_V2/ana_me_ICEC-SST-S-T-1980-2010/ana_19800115_me_mem??)

# plotReceipts: figures you want to plot, if none or empty means *.yml in Receipts/, Split with comma
#plotReceipts='01_test_receipt.yml'
plotReceipts='01_test_receipt.yml'

#--------------------------- case settings end -------------------------


# Machine related settings 
#--------------------------- machine settings begin -----------------------
## figures and webpages output directory, default is "$(pwd)/${plotCase}"
outputDir="$(pwd)/${plotCase}"

## observation or reanalysis data to compare, not done yet
obsDataDirs=''

## root directory of this package, sould contain doplot.py
diag_norcpm_Root='/nird/home/pgchiu/scratch/diag_norcpm'

## root directory of this package, sould contain doplot.py
defaultReceipt='/nird/home/pgchiu/scratch/diag_norcpm/Defaults.yml'

## python used to run doplot.py, develop with python3.4, but other version should ok.
PYTHON=$(which python)
NCL=$(which ncl)
#--------------------------- machine settings end -----------------------

# do plot
export plotCase ensDataDirs plotReceipts
export outputDir obsDataDirs diag_norcpm_Root defaultReceipt
export PYTHON NCL
"$PYTHON" "${diag_norcpm_Root}/doplot.py"

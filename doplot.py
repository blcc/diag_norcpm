#!/usr/bin/python3

import os,sys,re
import yaml
import subprocess as sp
from Codes.gen_proc_plot import gen_proc_plot

# get envrionment variables
plotCase            = os.environ.get('plotCase')
ensDataDirs         = os.environ.get('ensDataDirs').split()
plotReceipts        = os.environ.get('plotReceipts')
outputDir           = os.environ.get('outputDir')
obsDataDirs         = os.environ.get('obsDataDirs')
diag_norcpm_Root    = os.environ.get('diag_norcpm_Root')
DefaultYML          = os.environ.get('defaultReceipt')

# default directories and setting, begin -------------------------------------------------
ReceiptDir      = diag_norcpm_Root+'/Receipts/'
CodeDir         = diag_norcpm_Root+'/Codes/'
# default directories and setting, end -------------------------------------------------


# checking environment variables, begin ---------------------------------------
if not plotCase:
    print("plotCase is needed.")
    sys.exit()
if not ensDataDirs:
    print("ensDataDirs is needed.")
    sys.exit()
if not diag_norcpm_Root:
    print("diag_norcpm_Root cannot be remove.")
    print("    which contains doplot.py and recipts directory")
    sys.exit()
# checking environment variables, end -----------------------------------------

# read Defaults, begin -----------------------------------------
with open(DefaultYML,'r') as j:
    try:
        Defaults = yaml.load(j)
    except yaml.YAMLError as exc:
        print(exc)
#
# read Defaults, end -----------------------------------------

# list Receipts, begin -----------------------------------------
if not plotReceipts:
    plotReceipts = []
    for i in os.listdir(ReceiptDir):
        if re.match('.*\.(?:yml|json)$',i): plotReceipts.append(i) # accept yaml and json
else:
    plotReceipts = plotReceipts.split(',')

if not plotReceipts:
    print("No receipt in "+ReceiptDir+" or script")
    sys.exit()
# list Receipts, end -----------------------------------------

# list Codes, begin -----------------------------------------
## get attributes in Codes/*, make into {'script1':{'att1':'something01'},'script2':{'att100':'aaa100'}}
# list Codes, end -----------------------------------------



# Step 1 - process data, begin ------------------------------------------------
print('plot recipts: '+','.join(plotReceipts))
## before process
if not os.path.exists(outputDir): os.makedirs(outputDir)
### parse receipts
Receipts = []
for i in plotReceipts:
    receiptRootfn = os.path.splitext(os.path.basename(i))[0]
    with open(ReceiptDir+'/'+i,'r') as j:
        try:
            Rsuffix = os.path.splitext(i)[1]
            if Rsuffix == '.yml':
                receipt = yaml.load(j)
            elif Rsuffix == '.json':
                receipt = json.load(j)
            else:
                print("doplot.py: unsupport file: "+i)
                sys.exit()
            if type(receipt) == list:
                for r in receipt:
                    a = Defaults.copy()
                    a.update(r)
                    # add work directory with receipt file name
                    a.update({'figDir':receiptRootfn})
                    # add INPUTDIRS for replce dict
                    suffix = a.get("plotScript").split(".")[-1]
                    if suffix in ['ncl','py']:
                        a.update({'INPUTDIRS':",".join(['"'+i+'"' for i in ensDataDirs])})
                    elif suffix == 'sh':
                        a.update({'INPUTDIRS':" ".join([i for i in ensDataDirs])})
                    else:
                        print("doplot.py, suffix not support: "+suffix)
                        sys.exit()
                    Receipts.append(a)
            else:
                a = Defaults.copy()
                a.update(receipt)
                # add work directory with receipt file name
                a.update({'figDir':receiptRootfn})
                # add INPUTDIRS for replce dict
                suffix = a.get("plotScript").split(".")[-1]
                if suffix in ['ncl','py']:
                    a.update({'INPUTDIRS':",".join(['"'+i+'"' for i in ensDataDirs])})
                elif suffix is 'sh':
                    a.update({'INPUTDIRS':" ".join([i for i in ensDataDirs])})
                Receipts.append(a)
        except yaml.YAMLError as exc:
            print(exc)

### generate run script with plotScript with variables
num=0
plotScripts = []
for r in Receipts:
    figDir = r.get('figDir')
    if not os.path.exists(outputDir+'/'+figDir): os.makedirs(outputDir+'/'+figDir)
    res = gen_proc_plot(open(CodeDir+'/'+r.get("plotScript"),'r').read(),r)
    fn = str(num)+'-'+r.get("plotScript")
    plotScripts.append(figDir+'/'+fn)
    open(outputDir+'/'+figDir+'/'+fn,"w").write(res)
    num += 1

### output runall script
procs = []
pwd = os.getcwd()
runscript = open(outputDir+'/'+'runall.sh','w')
runscript.write('#!/bin/bash\n')
oldfigDir = ''
os.chdir(outputDir)
for p in plotScripts:
    figDir = os.path.dirname(p)
    if oldfigDir != figDir:
        runscript.write("cd "+outputDir+'\n')
        runscript.write("cd "+figDir+'\n')
        oldfigDir = figDir
        
    fn = os.path.basename(p)
    rootfn,suffix = os.path.splitext(fn)
    if suffix == '.ncl': 
        cmd = 'ncl'
    elif suffix == '.m': 
        cmd = 'matlab'
    elif suffix == '.py': 
        cmd = 'python'
    elif suffix == '.sh': 
        cmd = 'sh'
    else: 
        cmd = 'sh'  # bad idea

    logfile = rootfn+".log"
    runscript.write(cmd+" "+fn+" >& "+logfile+"\n")

runscript.close()
os.chdir(pwd)

### run all (not parallel yet)
os.chdir(outputDir)
for p in plotScripts:
    figDir = os.path.dirname(p)
    if figDir: os.chdir(outputDir+'/'+figDir)
    fn = os.path.basename(p)
    rootfn,suffix = os.path.splitext(fn)
    if suffix == '.ncl': 
        cmd = 'ncl'
    elif suffix == '.m': 
        cmd = 'matlab'
    elif suffix == '.py': 
        cmd = 'python'
    elif suffix == '.sh': 
        cmd = 'sh'
    else: 
        cmd = 'sh'  # bad idea

    logfile = outputDir+'/'+figDir.split('/')[-1]+".log"
    open(logfile,"a").write('>>>>>>>>>> running: '+fn+' <<<<<<<<<<<\n')
    print(cmd+" "+fn+" >> "+logfile)
    p = sp.call(cmd+" "+fn+" >> "+logfile,shell=True)
    open(logfile,"a").write('\n')
    


### wait all process done
#for p in procs:
    #p.wait()

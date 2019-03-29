import re
import sys
def gen_proc_plot(template:str,receipt):
    '''
        replace template string with dict(receipt)
    '''
    diagcmd = r';DIAG_NORCPM;' # read setting from ncl comments
    needcmd = 'need_be_replace'# special variable 

    ## planeize the receipt
    preceipt = {}
    for i in receipt.keys():
        if type(receipt[i]) is str: preceipt[i] = receipt[i]
        if type(receipt[i]) is dict: 
            for j in receipt[i].keys():
                if j in preceipt.keys(): print("gen_proc_plot: key confilct: "+j+' in '+str(receipt[i]))
                preceipt[j] = receipt[i][j]
        if type(receipt[i]) is list: 
            preceipt[i] = ",".join(['"'+j+'"' for j in receipt[i]])


    ## get necessary and default variables
    #cmds = re.match(diagcmd+r'.*',template)#.groups()
    keysinscript = dict()
    for line in template.split('\n'):
        cmdstr = re.search(diagcmd+r' *(.*)',line)
    #print(template)
        if cmdstr:
            cmd = re.search("^([^ :]*): *(.*)",cmdstr.group(1))
            if cmd:
                key = cmd.group(1)
                val = cmd.group(2)
                if val and val[0] == val[-1] and val[0] in ['"',"'"]: val = val[1:-1] ## remove ' and " if it indicate a string
                keysinscript.update({key:val})
            else:
                print('gen_proc_plot(): cannot parse: '+cmdstr.group(0))
    keysinscript.update(preceipt)

    ## check necessary variables are available
    OK = True
    needvars = keysinscript.get(needcmd)
    if needvars: 
        needvars = [i.strip() for i in needvars.split(',')]
        for i in needvars:
            if not i in keysinscript:
                OK = False
                print("gen_proc_plot(): "+i+" need be set for "+str(keysinscript.get('plotScript')))
    if not OK: 
        print(keysinscript)
        sys.exit()

    ## replace keys in template
    keys = [ i for i in keysinscript.keys()]
    keys.sort(key=len,reverse=True) 
    out = template
    #out = re.sub('\n;.*','',out)
    for i in keys:
        out = re.sub("\n([^;]*)"+i,r'\n\g<1>'+keysinscript[i],out)
        #out = re.sub(i,keysinscript[i],out)
        pass
    return out

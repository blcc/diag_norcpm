#!/bin/bash

#;DIAG_NORCPM; FIGFILES: 
    # figure files name "without suffix"
    # should be ps or png file
#;DIAG_NORCPM; HTMLFILENAME: index.html
#;DIAG_NORCPM; COMMENT: COMMENT here
#;DIAG_NORCPM; TITLE: TITLE here
#;DIAG_NORCPM; COLUMN: 1

# parameters
htmlfn="HTMLFILENAME"
comment="COMMENT"
title="TITLE"
figs="FIGFILES"
column=(COLUMN)
    ## number of figures in a row
    ## can be a array
ncolarr=${#column[*]}

# html header
echo ''
echo '<!DOCTYPE html>'              >  "${htmlfn}"
echo '<html>'                       >> "${htmlfn}"
echo '<body>'                       >> "${htmlfn}"

# put comment on top
echo '<div id=comment>'             >> "${htmlfn}"
echo '<p>'                          >> "${htmlfn}"
echo '<pre>'                        >> "${htmlfn}"
echo "$comment"                     >> "${htmlfn}"
echo '</pre>'                       >> "${htmlfn}"
echo '</p>'                         >> "${htmlfn}"
echo '</div>'                       >> "${htmlfn}"


# convert ps to png and output entry to html
pid=$$
row=1
icol=0
col=${column[$icol]}
for i in ${figs}; do
    if [ -f "${i}.ps" ] ; then ## ps2png
        convert -density 300 "${i}.ps" ${i}.png
        gzip -f "${i}.ps"
    fi 
    if [ -f "${i}.png" ] ; then ## trim white edge and make thumbnail
        convert ${i}.png  -trim tmp-${pid}.png 
        mv tmp-${pid}.png ${i}.png
        ## thumbnail
        convert -thumbnail 300 "${i}.png" "${i}_thumb.png"
        ## fig entry
        echo "<a href='${i}.png'><img src='${i}_thumb.png'></a>"    >> "${htmlfn}"
        if [ $row -ge $col ];then
            echo '</br>' >> "${htmlfn}"
            icol=$(expr $icol + 1)
            while [ ! -z "${column[$icol]}" ] ; do
                if [[ "${column[$icol]}" =~ ^[0-9]+$ ]] ; then
                    break
                else
                    echo "<b>${column[$icol]}</b>"    >> "${htmlfn}"
                    icol=$(expr $icol + 1)
                fi
            done
            if [ $icol -ge $ncolarr ];then
                icol=$(expr $ncolarr - 1)
            fi
            col=${column[$icol]}
            row=1
        else
            row=$(expr $row + 1)
        fi
    fi
done


# html footer
echo '</body>'  >>"${htmlfn}"
echo '</html> '  >>"${htmlfn}"

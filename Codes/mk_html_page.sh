#!/bin/bash

#;DIAG_NORCPM; PSFILE: sst_ts.ps
#;DIAG_NORCPM; HTMLFILENAME: index.html
#;DIAG_NORCPM; COMMENT: example comment
#;DIAG_NORCPM; TITLE: HTML TITLE

# parameters
htmlfn="HTMLFILENAME"
comment="COMMENT"
title="TITLE"

# convert ps to png
pid=$$
psfile=PSFILE
for i in $psfile; do
    if [ ! -f "${i}" ] ; then
        continue
    fi 
    convert -density 300 "${i}" tmp-${pid}.png
    convert tmp-${pid}.png -trim "${i%.*}".png
    rm -f tmp-${pid}.png
    gzip -f "${i}"
done


# html header
echo ''
echo '<!DOCTYPE html>'              >  "${htmlfn}"
echo '<html>'                       >> "${htmlfn}"
echo '<body>'                       >> "${htmlfn}"

# put comment on top
echo '<p>'                          >> "${htmlfn}"
echo '<pre>'                        >> "${htmlfn}"
echo "$comment"                     >> "${htmlfn}"
echo '</pre>'                       >> "${htmlfn}"
echo '</p>'                         >> "${htmlfn}"

# collect png to make thumbnail and produce html
pngs=$(ls *.png)
for i in ${pngs}; do
    ## thumbnail
    if [[ "${i}" == *"thumb.png"* ]];then
        continue
    fi
    thumb="${i%.*}_thumb.png"
    convert -thumbnail 300 "${i}" "${thumb}"
    echo "<a href='${i}'><img src='${thumb}'></a></br>"    >> "${htmlfn}"
done

# html footer
echo '</body>'  >>"${htmlfn}"
echo '</html> '  >>"${htmlfn}"
